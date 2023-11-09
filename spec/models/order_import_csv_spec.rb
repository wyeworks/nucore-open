require "rails_helper"

# This is a higher-level test. See order_import_spec and order_row_importer_spec
# for more details.
RSpec.describe OrderImport, feature_setting: { user_based_price_groups: true } do
  let(:facility) { create(:setup_facility) }

  describe "adding to existing orders" do
    let!(:user) { create(:user, username: "sst123@example.com") }
    let!(:item) { create(:setup_item, name: "Example Item", facility: facility) }
    let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
    let!(:account2) { create(:nufs_account, :with_account_owner, owner: user) }
    let!(:original_account) { create(:nufs_account, :with_account_owner, owner: user) }
    let!(:order) { create(:purchased_order, product: item, account: original_account, user: user, created_by: user.id) }
    let!(:order2) { create(:purchased_order, product: item, account: original_account, user: user, created_by: user.id) }
    let(:file) { create(:csv_stored_file, file: StringIO.new(body)) }
    let(:order_import) { described_class.new(facility: facility, created_by: user.id, upload_file: file) }
    let(:two_weeks_ago) { I18n.l(15.days.ago.to_date, format: :usa) } # 1
    let(:yesterday) { I18n.l(1.day.ago.to_date, format: :usa) } # 15
    let(:today) { I18n.l(Time.current.to_date, format: :usa) } #16

    describe "happy path" do
      let(:body) do
        <<~CSV
          #{I18n.t("order_row_importer.headers.user")},#{I18n.t("Chart_string")},Product Name,Quantity,Order Date,Fulfillment Date,Note,Order,Reference ID
          sst123@example.com,#{account.account_number},Example Item,1,#{yesterday},#{yesterday},Add to 1,#{order.id},123456789
          sst123@example.com,#{account2.account_number},Example Item,1,#{yesterday},#{yesterday},Add to 2,#{order.id},123456000
          sst123@example.com,#{account2.account_number},Example Item,1,#{yesterday},#{yesterday},Add to other,#{order2.id},abc123
          sst123@example.com,#{account.account_number},Example Item,1,#{yesterday},#{yesterday},New 1,,
          SST123@EXAMPLE.COM,#{account.account_number},Example Item,1,#{yesterday},#{yesterday},New 1-2 - Miscased,,
          sst123@example.com,#{account2.account_number},Example Item,1,#{yesterday},#{yesterday},New 2 - Different Account,,
          sst123@example.com,#{account2.account_number},Example Item,1,#{yesterday},#{yesterday},New 2-2,,1234
          sst123@example.com,#{account2.account_number},Example Item,1,#{two_weeks_ago},#{yesterday},New 3 - Different Order Date,,
          sst123@example.com,#{account2.account_number},Example Item,1,#{yesterday},#{today},New 2-3 - Different fulfilled,,
        CSV
      end

      it "adds the two items to the order" do
        expect { order_import.process_upload! }.to change(order.reload.order_details, :count).by(2)
      end

      it "puts the right accounts on the added details" do
        order_import.process_upload!
        expect(order.reload.order_details).to match([
          anything, # this is the original detail
          having_attributes(account: account, note: "Add to 1", reference_id: "123456789"),
          having_attributes(account: account2, note: "Add to 2", reference_id: "123456000"),
        ])
      end

      it "adds to the second order" do
        expect { order_import.process_upload! }.to change(order2.reload.order_details, :count).by(1)
      end

      it "creates additional orders based on the keys" do
        existing = Order.all.to_a
        expect { order_import.process_upload! }.to change(Order, :count).by(3)

        expect(Order.all.to_a - existing).to match([
          having_attributes(
            order_details: [
              having_attributes(account: account, note: "New 1"),
              having_attributes(account: account, note: "New 1-2 - Miscased"),
            ]
          ),
          having_attributes(
            order_details: [
              having_attributes(account: account2, note: "New 2 - Different Account"),
              having_attributes(account: account2, note: "New 2-2", fulfilled_at: 1.day.ago.beginning_of_day),
              having_attributes(account: account2, note: "New 2-3 - Different fulfilled", fulfilled_at: Time.current.beginning_of_day)
            ]
          ),
          having_attributes(
            order_details: [having_attributes(account: account2, note: "New 3 - Different Order Date")]
          ),
        ])
      end

    end
  end
end
