# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe OrderRowImporter do
  subject { OrderRowImporter.new(row, order_import) }
  let(:account) { create(Settings.testing.account_factory.to_sym, :with_account_owner, owner: user) }
  let!(:account_api_record) { create(Settings.testing.api_account_factory.to_sym, account_number: account.account_number) } if Settings.testing.api_account_factory
  let(:facility) { create(:setup_facility) }
  let(:order_import) { build(:order_import, creator: user, facility: facility) }
  let(:service) { create(:setup_service, facility: facility) }
  let(:user) { create(:user) }
  let(:project) { create(:project, facility:) }

  shared_context "valid row values" do
    let(:username) { user.username }
    let(:chart_string) { account.account_number }
    let(:product_name) { service.name }
    let(:quantity) { "1" }
    let(:order_date) { I18n.l(1.day.ago.to_date, format: :usa) }
    let(:fulfillment_date) { I18n.l(Time.current.to_date, format: :usa) }
    let(:reference_id) { "123456" }
    let(:project_name) { project.name }

    before(:each) do
      allow_any_instance_of(Product).to receive(:can_purchase?).and_return(true)
    end
  end

  let(:row) do
    ref = {
      "Netid / Email" => username,
      I18n.t("Chart_string") => chart_string,
      "Product Name" => product_name,
      "Quantity" => quantity,
      "Order Date" => order_date,
      "Fulfillment Date" => fulfillment_date,
      "Note" => notes,
      "Order" => order_number,
      "Reference ID" => reference_id,
      "Project Name" => project_name,
    }
    CSV::Row.new(ref.keys, ref.values)
  end

  let(:username) { "column1" }
  let(:chart_string) { "column2" }
  let(:product_name) { "column3" }
  let(:quantity) { "column4" }
  let(:order_date) { "column5" }
  let(:fulfillment_date) { "column6" }
  let(:notes) { "column7" }
  let(:order_number) { "" }
  let(:reference_id) { "column9" }
  let(:project_name) { "column10" }

  describe "#import" do
    shared_examples_for "an order was created" do
      it "creates an order" do
        expect { subject.import }.to change(Order, :count).by(1)
      end

      context "verifying the order" do
        let(:order) { Order.last }

        before { subject.import }

        it "has the expected ordered_at" do
          expect(order.order_details.map(&:ordered_at)).to all(eq SpecDateHelper.parse_usa_date(order_date))
        end

        it "has the expected creator" do
          expect(order.created_by_user).to eq user
        end

        it "has the expected user" do
          expect(order.user).to eq user
        end
      end
    end

    shared_examples_for "an order was not created" do
      it "does not create an order" do
        expect { subject.import }.not_to change(Order, :count)
      end

      it "does not add an order_detail" do
        expect { subject.import }.not_to change(OrderDetail, :count)
      end
    end

    shared_examples_for "it has an error message" do |message|
      before { subject.import }

      it "has the error message '#{message}'" do
        expect(subject.errors).to include(match /#{message}/)
      end
    end

    context "when the account is expired" do
      include_context "valid row values"

      let!(:account) do
        create(Settings.testing.account_factory.to_sym,
          :with_account_owner,
          owner: user,
          expires_at: 1.month.ago
        )
      end

      context "when the order occurred before the account expires" do
        let(:order_date) { I18n.l(50.days.ago.to_date, format: :usa) }
        let(:fulfillment_date) { I18n.l(45.days.ago.to_date, format: :usa) }

        it "creates an order" do
          expect { subject.import }.to change(Order, :count)
        end
      end

      context "when the order occurred after the account expires" do
        let(:order_date) { I18n.l(1.day.ago.to_date, format: :usa) }
        let(:fulfillment_date) { I18n.l(Time.current.to_date, format: :usa) }

        it "does not create an order" do
          expect { subject.import }.not_to change(Order, :count)
        end
      end
    end

    context "with a valid row" do
      include_context "valid row values"
      it_behaves_like "an order was created"

      it "has no errors" do
        subject.import
        expect(subject.errors).to be_empty
      end
    end

    context "with an empty row" do
      let(:username) { nil }
      let(:chart_string) { nil }
      let(:product_name) { nil }
      let(:quantity) { nil }
      let(:order_date) { nil }
      let(:fulfillment_date) { nil }
      let(:notes) { nil }
      let(:order_number) { nil }
      let(:reference_id) { nil }
      let(:project_name) { nil }

      before(:each) do
        allow_any_instance_of(Product).to receive(:can_purchase?).and_return(true)
      end

      it_behaves_like "an order was not created"

      it "has an error message" do
        subject.import
        expect(subject.errors).to eq(["All fields are empty"])
      end
    end

    context "when the reference_id field is missing" do
      include_context "valid row values"
      let(:reference_id) { "" }

      it_behaves_like "an order was created"
      it "has no errors" do
        subject.import
        expect(subject.errors).to be_empty
      end

      it "parses the reference_id" do
        subject.import
        expect(OrderDetail.last.reference_id).to be_blank
      end
    end

    context "when the reference_id field is present" do
      include_context "valid row values"

      it_behaves_like "an order was created"
      it "has no errors" do
        subject.import
        expect(subject.errors).to be_empty
      end

      it "parses the reference_id" do
        subject.import
        expect(OrderDetail.last.reference_id).to eq "123456"
      end
    end

    context "when the product starts in Pending Approval" do
      let(:order_status) { OrderStatus.find_or_create_by(name: "Pending Approval") }
      before { service.update(initial_order_status: order_status) }

      include_context "valid row values"
      it_behaves_like "an order was created"

      it "does not trigger any emails" do
        expect { subject.import }.not_to enqueue_mail
      end

      it "puts the order detail into Completed status" do
        subject.import
        expect(OrderDetail.last.state).to eq("complete")
        expect(OrderDetail.last.order_status.name).to eq("Complete")
      end

      it "puts the order into a purchased state" do
        subject.import
        expect(Order.last.state).to eq("purchased")
      end
    end

    context "when the fulfillment date" do
      shared_examples_for "an invalid fulfillment_date" do
        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Invalid Fulfillment Date"
      end

      context "is incorrectly formatted" do
        let(:fulfillment_date) { "4-Apr-13" }

        it_behaves_like "an invalid fulfillment_date"
      end

      context "has a 2-digit year" do
        let(:fulfillment_date) { "1/1/15" }

        it_behaves_like "an invalid fulfillment_date"
      end

      context "is impossible" do
        let(:fulfillment_date) { "02/31/2012" }

        it_behaves_like "an invalid fulfillment_date"
      end

      context "is nil" do
        let(:fulfillment_date) { nil }

        it_behaves_like "an invalid fulfillment_date"
      end

      context "is in the future" do
        let(:fulfillment_date) { I18n.l(1.day.from_now.to_date, format: :usa) }

        it_behaves_like "an invalid fulfillment_date"
      end

      context "it is today" do
        include_context "valid row values"
        let(:fulfillment_date) { I18n.l(Date.today, format: :usa) }

        it_behaves_like "an order was created"
      end
    end

    context "when the chart string" do
      context "is nil" do
        let(:username) { user.username }
        let(:product_name) { service.name }
        let(:chart_string) { nil }

        it_behaves_like "it has an error message", "Can't find account"
      end
    end

    context "when the order date is invalid" do
      shared_examples_for "an invalid order_date" do
        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Invalid Order Date"
      end

      context "is incorrectly formatted" do
        let(:order_date) { "4-Apr-13" }

        it_behaves_like "an invalid order_date"
      end

      context "has a 2-digit year" do
        let(:order_date) { "1/1/15" }

        it_behaves_like "an invalid order_date"
      end

      context "is impossible" do
        let(:order_date) { "02/31/2012" }

        it_behaves_like "an invalid order_date"
      end

      context "is nil" do
        let(:order_date) { nil }

        it_behaves_like "an invalid order_date"
      end

      context "is in the future" do
        let(:order_date) { I18n.l(1.day.from_now.to_date, format: :usa) }

        it_behaves_like "an invalid order_date"
      end

      context "it is today" do
        include_context "valid row values"
        let(:order_date) { I18n.l(Date.today, format: :usa) }

        it_behaves_like "an order was created"
      end
    end

    context "when the user is invalid" do
      context "when looking up by username" do
        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Invalid username"
      end

      context "when looking up by email address" do
        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Invalid username"
      end

      context "is nil" do
        let(:username) { nil }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Invalid username"
      end
    end

    context "when the product name is invalid" do
      it_behaves_like "an order was not created"
      it_behaves_like "it has an error message", "Couldn't find product by name"

      context "is nil" do
        let(:product_name) { nil }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Couldn't find product by name"
      end
    end

    context "when the product is a service" do
      let(:chart_string) { account.account_number }
      let(:price_group) { create(:price_group, facility: facility) }
      let(:product) { service }
      let(:product_name) { product.name }
      let(:username) { user.username }

      before(:each) do
        create(:user_price_group_member, user: user, price_group: price_group)
        product.service_price_policies.create(
          attributes_for(:service_price_policy, price_group: price_group),
        )
      end

      context "and it requires a survey" do
        before { allow_any_instance_of(Service).to receive(:active_survey?).and_return(true) }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Service requires survey"
      end

      context "and it requires a template" do
        before { allow_any_instance_of(Service).to receive(:active_template?).and_return(true) }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Service requires template"
      end
    end

    context "when the product is a timed service" do
      let(:chart_string) { account.account_number }
      let(:product) { create(:setup_timed_service, facility: facility) }
      let(:username) { user.username }

      describe "happy path" do
        include_context "valid row values" do
          let(:product_name) { product.name }
          let(:quantity) { "90" }
        end

        it_behaves_like "an order was created"

        it "parses the quantity" do
          subject.import
          expect(OrderDetail.last.quantity).to eq(90)
        end

        it "has no errors" do
          subject.import
          expect(subject.errors).to be_empty
        end
      end

      describe "hh:mm format" do
        include_context "valid row values" do
          let(:product_name) { product.name }
          let(:quantity) { "1:30" }
        end

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Quantity is not a valid number"
      end
    end

    describe "when the product is an instrument" do
      let(:chart_string) { account.account_number }
      let(:price_group) { create(:price_group, facility: facility) }
      let(:product) { create(:setup_instrument, facility: facility) }
      let(:product_name) { product.name }
      let(:username) { user.username }

      before(:each) do
        create(:user_price_group_member, user: user, price_group: price_group)
        product.instrument_price_policies.create(
          attributes_for(:instrument_price_policy, price_group: price_group),
        )
      end

      it_behaves_like "an order was not created"
      it_behaves_like "it has an error message", "Instrument orders not allowed"
    end

    context "when the user has an account for the product's facility" do
      let(:chart_string) { account.account_number }
      let(:order_date) { I18n.l(Time.current.to_date, format: :usa) }
      let(:fulfillment_date) { I18n.l(Time.current.to_date, format: :usa) }
      let(:product) { service }
      let(:product_name) { product.name }
      let(:username) { user.username }
      let(:project_name) { nil }

      before(:each) do
        allow_any_instance_of(User).to receive(:accounts)
          .and_return(Account.where(id: account.id))
      end

      context "and the account is active" do
        before { allow_any_instance_of(Account).to receive(:active?).and_return(true) }

        context "and the account is invalid for the product" do
          before(:each) do
            allow_any_instance_of(Facility).to receive(:can_pay_with_account?).and_return(false)
          end

          it_behaves_like "an order was not created"
          it_behaves_like "it has an error message", "does not accept #{Settings.testing.account_class_name.constantize.model_name.human} payment"
        end

        context "and the account is valid for the product" do
          before { allow_any_instance_of(Product).to receive(:can_purchase?).and_return(true) }

          context "when the order was not purchased" do
            before(:each) do
              allow_any_instance_of(Order).to receive(:purchased?).and_return(false)
              allow_any_instance_of(Order).to receive(:purchase_without_default_status!).and_return(false)
            end

            context "and the order is valid" do
              before(:each) do
                allow_any_instance_of(Order).to receive(:validate_order!).and_return(true)
              end

              context "and is not purchaseable" do
                # Creating an Order in this case is existing behavior.
                # In practice we run the import in a transaction and roll back.
                it_behaves_like "an order was created"
                it_behaves_like "it has an error message", "Couldn't purchase order"
              end

              context "and the product is deactivated (archived)" do
                before { product.update_attribute(:is_archived, true) }

                it_behaves_like "an order was not created"
                it_behaves_like "it has an error message", "Couldn't find product"
              end

              context "and the product is hidden" do
                before(:each) do
                  product.update_attribute(:is_hidden, true)
                  allow_any_instance_of(Order).to receive(:purchase_without_default_status!).and_return(true)
                end

                it_behaves_like "an order was created"

                it "has no errors" do
                  subject.import
                  expect(subject.errors).to be_empty
                end
              end
            end

            context "and the order is invalid" do
              # Creating an Order in this case is existing behavior.
              # In practice we run the import in a transaction and roll back.
              it_behaves_like "an order was created"
              it_behaves_like "it has an error message", "Couldn't validate order"
            end
          end
        end
      end

      context "and the account is inactive" do
        before { account.update_attribute(:suspended_at, 1.year.ago) }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Can't find account"
      end
    end

    context "when the headers are invalid" do
      let(:row) do
        ref = {
          "Netid / Email" => username,
          "acct" => chart_string,
          "Product Name" => product_name,
          "Quantity" => quantity,
          "Order Date" => order_date,
          "Fulfillment Date" => fulfillment_date,
          "Note" => notes,
        }
        CSV::Row.new(ref.keys, ref.values)
      end

      let(:username) { user.username }
      let(:chart_string) { account.account_number }
      let(:product_name) { service.name }
      let(:quantity) { 1 }
      let(:order_date) { I18n.l(Time.current.to_date, format: :usa) }
      let(:fulfillment_date) { I18n.l(Time.current.to_date, format: :usa) }

      before(:each) do
        allow_any_instance_of(Product).to receive(:can_purchase?).and_return(true)
      end

      it_behaves_like "an order was not created"
      it_behaves_like "it has an error message", "Missing headers: #{I18n.t('Chart_string')}"
    end

    context "when the note field is invalid" do
      include_context "valid row values"

      context "it is too long" do
        let(:notes) { "a" * 1001 }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "Note is too long"
      end
    end

    context "when adding to an existing order" do
      include_context "valid row values" do
        let(:order_number) { existing_order.id.to_s }
      end

      context "happy path" do
        let!(:existing_order) { create(:purchased_order, product: service, user: user, account: account) }

        it "adds to the existing order" do
          expect { subject.import }.to change(OrderDetail, :count).by(1).and change(Order, :count).by(0)
          expect(OrderDetail.last.order).to eq(existing_order)
        end
      end

      context "when the order is not found" do
        let(:order_number) { "0" }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "The order could not be found"
      end

      context "when the order is not purchased" do
        let!(:existing_order) { create(:setup_order, product: service, user: user, account: account) }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "The order has not been purchased"
      end

      context "when the order is part of a different facility" do
        let!(:existing_order) { create(:purchased_order, product: other_facility_product, user: user, account: account) }
        let(:other_facility) { create(:setup_facility) }
        let(:other_facility_product) { create(:setup_item, facility: other_facility) }

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "The order belongs to another facility"
      end

      context "when the user is wrong" do
        let!(:existing_order) { create(:purchased_order, product: service, account: account, user: other_user) }
        let(:other_user) do
          create(:user, username: "otheruser") do |other_user|
            other_user.account_users << AccountUser.new(account: account, user_role: AccountUser::ACCOUNT_PURCHASER, created_by: 0)
          end
        end

        it_behaves_like "an order was not created"
        it_behaves_like "it has an error message", "The user does not match the existing order's"
      end
    end

    context "with existing project name" do
      include_context "valid row values"
      it "creates an order detail with a project" do
        subject.import
        expect(subject.errors).to be_empty
        expect(OrderDetail.last.project_id).to eq project.id
      end
    end

    context "with non-existing project name" do
      include_context "valid row values"
      let(:project_name) { "Non-existing project" }

      it "produces and error" do
        subject.import
        expect(subject.errors).to eq ["Project not found"]
      end
    end

    context "with an empty string as a project name" do
      include_context "valid row values"
      let(:project_name) { "" }

      it "creates an order detail with no project" do
        subject.import
        expect(subject.errors).to be_empty
        expect(OrderDetail.last.project_id).to be_nil
      end
    end
  end

  context "order key construction" do
    let(:expected_order_key) { %w(column1 column2 column5) }

    describe ".order_key_for_row" do
      it "builds an array based on the expected fields" do
        expect(OrderRowImporter.order_key_for_row(row)).to eq expected_order_key
      end
    end

    describe "#order_key" do
      it "builds an array based on the expected fields" do
        expect(subject.order_key).to eq expected_order_key
      end
    end
  end

  describe "#row_with_errors" do
    let(:errors) { %w(one two three) }
    let(:row) do
      {
        "Netid / Email" => username,
        I18n.t("Chart_string") => chart_string,
        "Product Name" => product_name,
        "Quantity" => quantity,
        "Order Date" => order_date,
        "Fulfillment Date" => fulfillment_date,
      }
    end

    context "when the import has no errors" do
      it "does not add errors to the error column" do
        expect(subject.row_with_errors["Errors"]).to be_blank
      end
    end

    context "when the import has errors" do
      before { errors.each { |error| subject.send(:add_error, error) } }

      it "adds errors to the error column" do
        expect(subject.row_with_errors["Errors"]).to eq(errors.join(", "))
      end
    end
  end
end
