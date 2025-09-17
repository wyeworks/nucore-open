# frozen_string_literal: true

require "rails_helper"
require "product_shared_examples"

RSpec.describe Item do
  let(:facility) { create(:setup_facility) }
  let(:facility_account) { create(:facility_account, facility:) }

  it "can create using a factory" do
    item = create(:item, facility:, facility_account:)
    expect(item).to be_valid
    expect(item.type).to eq("Item")
  end

  it_should_behave_like "NonReservationProduct", :item

  describe "initial_order_status" do
    let(:item) { build(:item, facility:, facility_account:) }
    let(:complete_status) { OrderStatus.complete }

    context "when item_initial_order_status_complete feature is on", feature_setting: { item_initial_order_status_complete: true } do
      it "can be created with Complete as initial order status" do
        item = build(:item,
                     facility:,
                     facility_account:,
                     initial_order_status: complete_status
                    )

        expect(item).to be_valid
        expect(item.initial_order_status).to eq(complete_status)
      end

      it "can still be created with default (New) status" do
        item = build(:item,
                     facility:,
                     facility_account:
                    )

        expect(item).to be_valid
        expect(item.initial_order_status.name).to eq("New")
      end
    end

    context "when item_initial_order_status_complete feature is off", feature_setting: { item_initial_order_status_complete: false } do
      it "uses default (New) status when not specified" do
        item = build(:item,
                     facility:,
                     facility_account:
                    )

        expect(item).to be_valid
        expect(item.initial_order_status.name).to eq("New")
      end

      it "does not include Complete in available initial statuses for Items" do
        available_statuses = OrderStatus.initial_statuses(facility, product: item)

        expect(available_statuses).not_to include(complete_status)
        expect(available_statuses.map(&:name)).to include("New", "In Process")
        expect(available_statuses.map(&:name)).not_to include("Complete")
      end
    end
  end

end
