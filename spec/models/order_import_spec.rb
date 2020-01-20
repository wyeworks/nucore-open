# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

require "stringio"

RSpec.describe OrderImport, :time_travel do

  CSV_HEADERS = [
    "Netid / Email",
    "Chart String",
    "Product Name",
    "Quantity",
    "Order Date",
    "Fulfillment Date",
    "Note",
  ].freeze

  def nucore_format_date(date)
    date.strftime("%m/%d/%Y")
  end

  let(:now) { fiscal_year_beginning + 5.days }

  subject(:order_import) do
    OrderImport.create!(
      created_by: director.id,
      upload_file: stored_file,
      facility: facility,
    )
  end

  let(:account) do
    create(:nufs_account,
           description: "dummy account",
           account_users_attributes: account_users_attributes,
          )
  end

  let(:account_users_attributes) do
    account_users_attributes_hash(user: guest) +
      account_users_attributes_hash(
        user: guest2,
        created_by: guest,
        user_role: AccountUser::ACCOUNT_PURCHASER,
      )
  end
  let(:default_order_date) { 4.days.ago.to_date }
  let(:default_fulfilled_date) { 3.days.ago.to_date }
  let(:director) { @director }
  let(:error_file_row_count) do
    Paperclip
      .io_adapters
      .for(order_import.error_file.file)
      .read
      .split("\n")
      .count
  end
  let(:facility) { create(:facility) }
  let(:facility_account) { create(:facility_account, facility: facility) }
  let(:fiscal_year_beginning) { SettingsHelper.fiscal_year_beginning }
  let(:guest) { @guest }
  let(:guest2) { create(:user, username: "guest2") }
  let(:import_file_row_count) { import_file.read.split("\n").count }
  let(:item) do
    facility.items.create!(attributes_for(:item,
                                          facility_account_id: facility_account.id,
                                          name: "Example Item",
                                         ))
  end
  let(:service) do
    facility.services.create!(attributes_for(:service,
                                             facility_account_id: facility_account.id,
                                             name: "Example Service",
                                            ))
  end
  let(:stored_file) do
    StoredFile.create!(
      file: StringIO.new("c,s,v"),
      file_type: "import_upload",
      name: "clean_import.csv",
      created_by: director.id,
    )
  end

  before(:all) { create_users }

  before :each do
    grant_role(director, facility)

    price_group = FactoryBot.create(:price_group, facility: facility)
    create(:account_price_group_member, account: account, price_group: price_group)
    item.item_price_policies.create!(attributes_for(:item_price_policy,
                                                    price_group_id: price_group.id,
                                                    start_date: fiscal_year_beginning,
                                                   ))
    service.service_price_policies.create!(attributes_for(:service_price_policy,
                                                          price_group_id: price_group.id,
                                                          start_date: fiscal_year_beginning,
                                                         ))
  end

  shared_examples_for "it does not send notifications" do
    it "does not send notifications" do
      expect(PurchaseNotifier).to receive(:order_receipt).never
      order_import.process_upload!
    end
  end

  context "validations" do
    it { is_expected.to belong_to :creator }
    it { is_expected.to belong_to(:upload_file).required }
    it { is_expected.to belong_to :error_file }
    it { is_expected.to validate_presence_of :upload_file }
    it { is_expected.to validate_presence_of :created_by }
  end

  def generate_import_file(*args)
    args = [{}] if args.length == 0 # default to at least one valid row

    whole_csv = CSV.generate headers: true do |csv|
      csv << CSV_HEADERS
      args.each do |opts|
        row = CSV::Row.new(CSV_HEADERS, [
                             opts[:username] || "guest",
                             opts[:account_number]     || account.account_number,
                             opts[:product_name]       || "Example Item",
                             opts[:quantity]           || "1",
                             opts[:order_date]         || nucore_format_date(default_order_date),
                             opts[:fullfillment_date]  || nucore_format_date(default_fulfilled_date),
                             opts[:note]               || "Test Note",
                           ])
        csv << row
      end
    end

    StringIO.new whole_csv
  end

  context "when in save-clean-orders mode" do
    let(:import_file) do
      generate_import_file(
        # First order:
        { order_date: nucore_format_date(default_order_date) },
        { order_date: nucore_format_date(default_order_date) },
        # Second order (a different order_date):
        order_date: nucore_format_date(default_order_date + 1.day),
        product_name: "Invalid Item",
      )
    end

    before :each do
      order_import.fail_on_error = false
      order_import.send_receipts = true
      order_import.upload_file.file = import_file
      order_import.upload_file.save!
      order_import.save!
    end

    it "sends notifications" do
      expect(PurchaseNotifier)
        .to receive(:order_receipt)
        .once
        .and_return(double(deliver_later: nil))

      order_import.process_upload!
    end
  end

  context "when in save-nothing-on-error mode" do
    before :each do
      order_import.fail_on_error = true
      order_import.send_receipts = send_receipts
      order_import.upload_file.file = import_file
      order_import.upload_file.save!
      order_import.save!
    end

    context "with notifications enabled" do
      let(:send_receipts) { true }

      context "with errors" do
        let(:import_file) do
          generate_import_file({}, product_name: "Invalid Item")
        end

        it_behaves_like "it does not send notifications"
      end

      context "with no errors" do
        let(:import_file) { generate_import_file }

        it "sends notifications" do
          expect(PurchaseNotifier)
            .to receive(:order_receipt)
            .once
            .and_return(double(deliver_later: nil))

          order_import.process_upload!
        end
      end
    end

    context "with notifications disabled" do
      let(:import_file) { generate_import_file }
      let(:send_receipts) { false }

      it_behaves_like "it does not send notifications"
    end
  end

  context "importing two orders" do
    context "when one order_detail has an error" do
      let(:import_file) do
        generate_import_file(
          # First order:
          { product_name: "Invalid Item" },
          {},
          # Second order (a different user):
          username: guest2.username,
        )
      end

      before :each do
        Order.destroy_all
        order_import.upload_file.file = import_file
        order_import.upload_file.save!

        order_import.send_receipts = true
        order_import.save!

        import_file.rewind # because #save! reads the file
      end

      context "when in save-nothing-on-error mode" do
        before :each do
          order_import.fail_on_error = true
          order_import.save!
        end

        it "creates no orders" do
          expect { order_import.process_upload! }.not_to change(Order, :count)
        end

        it_behaves_like "it does not send notifications"

        it "includes all rows in its error report" do
          order_import.process_upload!
          expect(error_file_row_count).to eq(import_file_row_count)
        end
      end

      context "when in save-clean-orders mode" do
        before :each do
          order_import.fail_on_error = false
          order_import.save!
        end

        it "creates an order" do
          expect { order_import.process_upload! }.to change(Order, :count).by(1)
        end

        it "sends a notification for second order" do
          expect(PurchaseNotifier)
            .to receive(:order_receipt)
            .once
            .and_return(double(deliver_later: nil))

          order_import.process_upload!
        end

        it "has the first two rows in its error report" do
          order_import.process_upload!

          # minus one because one order (and order_detail) will succeed
          expect(error_file_row_count).to eq(import_file_row_count - 1)
        end
      end
    end
  end

  context "when importing multiple orders" do
    context "and the second order's order_detail has an error" do
      let(:import_file) do
        generate_import_file({}, product_name: "Invalid Item")
      end

      before :each do
        Order.destroy_all
        order_import.upload_file.file = import_file
        order_import.upload_file.save!
        import_file.rewind

        order_import.fail_on_error = fail_on_error
        order_import.send_receipts = true
        order_import.save!
      end

      shared_examples_for "an import failure" do
        it "creates no orders" do
          expect { order_import.process_upload! }.not_to change(Order, :count)
        end

        it_behaves_like "it does not send notifications"

        it "includes all rows in its error report (as there's only one order)" do
          order_import.process_upload!
          expect(error_file_row_count).to eq(import_file_row_count)
        end
      end

      context "when in save-clean-orders mode" do
        let(:fail_on_error) { false }

        it_behaves_like "an import failure"
      end

      context "when in save-nothing-on-error mode" do
        let(:fail_on_error) { true }

        it_behaves_like "an import failure"
      end
    end
  end

  describe "#process_upload!" do
    subject(:import) { create(:order_import) }

    context "an exception is raised in import" do
      before do
        allow_any_instance_of(OrderRowImporter).to receive(:import).and_raise("Something unknown happened")
        import.upload_file.file = generate_import_file
        import.upload_file.save!
        import.process_upload!
      end

      it "produces an error report" do
        expect(import.error_file_content).to include("Failed to import row")
      end

      it "sets error flags" do
        expect(import).to be_error_mode
        expect(import.result).to be_failed
      end

      it "sends an exception notification" do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("background_error", anything)
        import.process_upload!
      end
    end

    context "an exception is raised when opening the CSV" do
      before do
        allow(CSV).to receive(:parse).and_raise(ArgumentError, "invalid byte sequence in UTF-8")
        import.upload_file.file = generate_import_file
        import.upload_file.save!
        import.process_upload!
      end

      it "produces an error report" do
        expect(import.error_file_content).to include("Unable to open CSV File")
      end

      it "sets error flags" do
        expect(import).to be_error_mode
        expect(import.result).to be_failed
      end
    end
  end
end
