# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderRowImporter do
  subject { OrderRowImporter.new(row, order_import) }

  let(:secure_room) { create(:secure_room) }
  let(:facility) { secure_room.facility }
  let(:user) { create(:user) }
  let(:order_import) { build(:order_import, creator: user, facility:) }
  let(:account) { create(:nufs_account, :with_account_owner, owner: user) }

  let(:row) do
    ref = {
      "Netid / Email" => user.username,
      "Chart String" => account.account_number,
      "Product Name" => secure_room.name,
      "Quantity" => "1",
      "Order Date" => "12/16/2016",
      "Fulfillment Date" => "12/16/2016",
      "Errors" => "",
      "Note" => "",
    }
    CSV::Row.new(ref.keys, ref.values)
  end

  it "does not allow importing secure rooms" do
    expect { subject.import }.not_to change(OrderDetail, :count)

    # Errors is an array, so find one item matching the substring
    expect(subject.errors).to include(include("Secure Room orders not allowed"))
  end
end
