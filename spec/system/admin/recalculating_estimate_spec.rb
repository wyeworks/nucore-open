# frozen_string_literal: true

require "rails_helper"

RSpec.describe(
  "Recalculating an estimate", :js,
  feature_setting: { user_based_price_groups: true },
) do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let!(:user) { create(:user) }
  let(:price_group) { user.price_groups.first }
  let!(:item) { create(:setup_item, facility:) }
  let!(:item_price_policy) { create(:item_price_policy, product: item, price_group:) }
  let!(:estimate) { create(:estimate, user:, facility:, estimate_details: [create(:estimate_detail, product: item, quantity: 2)]) }

  before { login_as director }

  it "can recalculate an estimate" do
    visit facility_estimate_path(facility, estimate)

    previous_price = item_price_policy.unit_cost

    expect(page).to have_content "Estimate ##{estimate.id} - Test Estimate"
    expect(page).to have_content item.name
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(previous_price * 2) # 2 items

    new_price = 50
    item_price_policy.update(unit_cost: new_price)

    click_link "Recalculate"

    expect(page).to have_content "Estimate successfully recalculated"
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(new_price * 2) # 2 items
    expect(page).to_not have_content ActionController::Base.helpers.number_to_currency(previous_price * 2)
  end
end
