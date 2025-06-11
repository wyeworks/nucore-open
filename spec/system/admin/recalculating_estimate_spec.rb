# frozen_string_literal: true

require "rails_helper"

RSpec.describe(
  "Recalculating an estimate", :js
) do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let!(:user) { create(:user) }
  let(:price_group) { facility.price_groups.first }
  let!(:item) { create(:setup_item, facility:) }
  let!(:item_price_policy) { create(:item_price_policy, product: item, price_group:) }
  let!(:estimate) { create(:estimate, created_at: 1.week.ago, updated_at: 1.week.ago, user:, created_by_user: director, price_group:, facility:) }

  before do
    estimate.estimate_details.create(product: item, quantity: 2, created_at: 3.hours.ago, updated_at: 3.hours.ago)

    login_as director
  end

  it "can recalculate an estimate" do
    visit facility_estimate_path(facility, estimate)

    previous_price = item_price_policy.unit_cost

    expect(page).to have_content "Estimate ##{estimate.id} - Test Estimate"
    expect(page).to have_content item.name
    expect(page).to have_content price_group.name
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(previous_price * 2) # 2 items

    new_price = 50
    item_price_policy.update(unit_cost: new_price)

    click_link "Recalculate"

    expect(page).to have_content "Estimate successfully recalculated"
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(new_price * 2) # 2 items
    expect(page).to_not have_content ActionController::Base.helpers.number_to_currency(previous_price * 2)
    updated_at = estimate.reload.estimate_details.maximum(:updated_at)
    expect(updated_at).to be > 3.hours.ago
    expect(page).to have_content "Prices last updated: #{I18n.l(updated_at, format: :usa)}"
  end

  context "when recalculating fails" do
    let(:another_price_group) { create(:price_group, facility:) }

    before do
      estimate.update_columns(price_group_id: another_price_group.id)

      visit facility_estimate_path(facility, estimate)
    end

    it "redirects to edit page" do
      click_link "Recalculate"

      expect(page).to have_content "Edit Estimate"
      expect(page).to have_content "No price policy found."
    end
  end
end
