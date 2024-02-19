# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe Projects::OrderRowImporterExtension do
  subject { OrderRowImporter.new(row, order_import) }
  let(:account) { create(Settings.testing.account_factory.to_sym, :with_account_owner, owner: user) }
  let!(:account_api_record) { create(Settings.testing.api_account_factory.to_sym, account_number: account.account_number) } if Settings.testing.api_account_factory
  let(:facility) { create(:setup_facility) }
  let(:project) { create(:project, facility:) }
  let(:order_import) { build(:order_import, creator: user, facility:) }
  let(:service) { create(:setup_service, facility:) }
  let(:user) { create(:user) }
  let(:username) { user.username }
  let(:chart_string) { account.account_number }
  let(:product_name) { service.name }
  let(:quantity) { "1" }
  let(:order_date) { I18n.l(1.day.ago.to_date, format: :usa) }
  let(:fulfillment_date) { I18n.l(Time.current.to_date, format: :usa) }
  let(:reference_id) { "123456" }

  let(:row) do
    ref = {
      "Netid / Email" => username,
      I18n.t("Chart_string") => chart_string,
      "Product Name" => product_name,
      "Quantity" => quantity,
      "Order Date" => order_date,
      "Fulfillment Date" => fulfillment_date,
      "Note" => "This is a note",
      "Reference ID" => reference_id,
      "Project ID" => project.id,
    }
    CSV::Row.new(ref.keys, ref.values)
  end

  before(:each) do
    allow_any_instance_of(Product).to receive(:can_purchase?).and_return(true)
  end

  describe "#import" do
    it "creates an order detail with a project" do
      subject.import
      expect(subject.errors).to be_empty
      expect(OrderDetail.last.project_id).to eq project.id
    end
  end

  it "has all of the columns in the correct order" do
    expect(subject.row_with_errors.headers).to eq(
      [
        "Netid / Email",
        I18n.t("Chart_string"),
        "Product Name",
        "Quantity",
        "Order Date",
        "Fulfillment Date",
        "Note",
        "Order",
        "Reference ID",
        "Errors",
        "Project ID",
      ],
    )
  end
end
