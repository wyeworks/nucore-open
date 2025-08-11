# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailNoticesUpdateJob do
  let(:product) { create(:setup_item) }
  let(:order) { create(:complete_order, product:) }
  let(:order_detail) { order.order_details.last }

  it "does not create a new order_detail version history" do
    expect { described_class.perform_now(order_detail) }.not_to(
      change do
        order_detail.versions.count
      end
    )
  end

  it "does update problem flag without touching the order update time" do
    order_detail.update_columns(problem: true)

    expect { described_class.perform_now(order_detail) }.not_to(
      change do
        order_detail.reload.updated_at
      end
    )

    expect(order_detail.problem).to be false
  end
end
