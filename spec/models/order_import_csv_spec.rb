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

    describe "happy path" do
      let(:body) do
        <<~CSV
          Netid / Email,Chart String,Product Name,Quantity,Order Date,Fulfillment Date,Note,Order
          sst123@example.com,#{account.account_number},Example Item,1,02/15/2020,02/15/2020,Add to 1,#{order.id}
          sst123@example.com,#{account2.account_number},Example Item,1,02/15/2020,02/15/2020,Add to 2,#{order.id}
          sst123@example.com,#{account2.account_number},Example Item,1,02/15/2020,02/15/2020,Add to other,#{order2.id}
          sst123@example.com,#{account.account_number},Example Item,1,02/15/2020,02/15/2020,New 1,
          SST123@EXAMPLE.COM,#{account.account_number},Example Item,1,02/15/2020,02/15/2020,New 1-2 - Miscased,
          sst123@example.com,#{account2.account_number},Example Item,1,02/15/2020,02/15/2020,New 2 - Different Account,
          sst123@example.com,#{account2.account_number},Example Item,1,02/15/2020,02/15/2020,New 2-2,
          sst123@example.com,#{account2.account_number},Example Item,1,02/01/2020,02/15/2020,New 3 - Different Order Date,
          sst123@example.com,#{account2.account_number},Example Item,1,02/15/2020,02/16/2020,New 2-3 - Different fulfilled,
        CSV
      end

      it "adds the two items to the order" do
        expect { order_import.process_upload! }.to change(order.reload.order_details, :count).by(2)
      end

      it "puts the right accounts on the added details" do
        order_import.process_upload!
        expect(order.reload.order_details).to match([
          anything, # this is the original detail
          having_attributes(account: account, note: "Add to 1"),
          having_attributes(account: account2, note: "Add to 2"),
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
              having_attributes(account: account2, note: "New 2-2", fulfilled_at: Time.zone.parse("2020-02-15")),
              having_attributes(account: account2, note: "New 2-3 - Different fulfilled", fulfilled_at: Time.zone.parse("2020-02-16"))
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
