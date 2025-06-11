# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Estimate Duplication", :js do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let!(:user) { create(:user) }
  let(:price_group) { facility.price_groups.first }
  let!(:item) { create(:setup_item, facility:) }
  let!(:item_price_policy) { create(:item_price_policy, product: item, price_group:) }
  let!(:estimate) { create(:estimate, created_at: 1.week.ago, updated_at: 1.week.ago, user:, created_by_user: director, price_group:, facility:) }

  before do
    estimate.estimate_details.create(product: item, quantity: 2)

    login_as director
  end

  it "can duplicate an estimate" do
    visit facility_estimate_path(facility, estimate)

    previous_cost = estimate.total_cost
    new_price = 50
    item_price_policy.update(unit_cost: new_price)

    click_link "Duplicate Estimate"

    expect(page).to have_current_path(facility_estimate_path(facility, Estimate.last))
    expect(page).to have_content("Estimate successfully duplicated")

    new_estimate = Estimate.last
    estimate_detail = estimate.estimate_details.first

    expect(new_estimate.id).not_to eq(estimate.id)
    expect(new_estimate.description).to eq("Copy of #{estimate.description}")
    expect(new_estimate.note).to eq(estimate.note)
    expect(new_estimate.user).to eq(estimate.user)
    expect(new_estimate.price_group).to eq(estimate.price_group)
    expect(new_estimate.expires_at).to eq(1.month.from_now)

    expect(new_estimate.estimate_details.count).to eq(estimate.estimate_details.count)
    new_detail = new_estimate.estimate_details.first
    expect(new_detail.product).to eq(estimate_detail.product)
    expect(new_detail.quantity).to eq(estimate_detail.quantity)
    expect(new_detail.cost).to eq(new_price * 2)
  end

  context "when duplication fails" do
    before do
      # Force duplicated estimate to be invalid
      item_price_policy.destroy!
    end

    it "redirects to the new estimate form and shows an error" do
      visit facility_estimate_path(facility, estimate)
      click_link "Duplicate Estimate"

      expect(page).to have_content("There was an error duplicating the estimate")

      expect(page).to have_css("form.new_estimate")

      expect(page).to have_field("Description", with: "Copy of #{estimate.description}")
      expect(page).to have_field("Expires at", with: I18n.l(estimate.expires_at.to_date, format: :usa))
      expect(page).to have_field("Notes", with: estimate.note)

      within("#estimate_products_table") do
        estimate.estimate_details.each do |estimate_detail|
          expect(page).to have_content(estimate_detail.product.name)
          expect(page).to have_css(".error-inline", text: "No price policy found.")
        end
      end
    end
  end
end
