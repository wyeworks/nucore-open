# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Placing an item order" do
  let!(:product) { FactoryBot.create(:setup_item) }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { product.facility }
  let!(:price_policy) do
    FactoryBot.create(:item_price_policy,
                      price_group: PriceGroup.base,
                      product: product,
                      unit_cost: 33.25,
                      start_date: 2.days.ago)
  end
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end
  let(:user) { FactoryBot.create(:user) }
  let(:facility_admin) { FactoryBot.create(:user, :facility_administrator, facility: facility) }

  before do
    login_as facility_admin
    visit facility_users_path(facility)
    fill_in "search_term", with: user.email
    click_button "Search"
    click_link "Order For"
  end

  it "can place an order" do
    visit facility_path(facility)
    click_link product.name
    click_link "Add to cart"
    choose account.to_s
    click_button "Continue"

    click_button "Purchase"
    expect(page).to have_content "Order Receipt"
    expect(page).to have_content "Ordered For\n#{user.full_name}"
    expect(page).to have_content "$33.25"
  end

  describe "trying to purchase after updating the quantity" do
    before do
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
      fill_in "Note", with: "A note"
      fill_in "Reference ID", with: "Ref123"
      fill_in "Quantity", with: "45"
      click_button "Purchase"
    end

    it "returns to the cart, and the fields are properly updated" do
      expect(page).to have_content "Quantities have changed."
      expect(page).to have_field("Note", with: "A note")
      expect(page).to have_field("Reference ID", with: "Ref123")
      expect(page).to have_field("Quantity", with: "45")
    end
  end

  describe "trying to purchase after updating just the note/ref id fields" do
    before do
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
      fill_in "Note", with: "A note"
      fill_in "Reference ID", with: "Ref123"
      click_button "Purchase"
    end

    it "purchases" do
      expect(page).to have_content("Order Receipt")
      expect(page).to have_content("Note: A note")
    end
  end

  it "can backdate an order", :js do # js needed for More options expansion
    visit facility_path(facility)
    click_link product.name
    click_link "Add to cart"
    choose account.to_s
    click_button "Continue"

    find("label", text: /More options/i).click
    fill_in "Order date", with: I18n.l(2.days.ago.to_date, format: :usa)
    select "Complete", from: "Order Status"

    click_button "Purchase"

    expect(page).to have_content "Order Receipt"
    expect(page).to have_content(/Ordered For\n#{user.full_name}/i)
    expect(page).to have_css(".currency .estimated_cost", count: 0)
    expect(page).to have_css(".currency .actual_cost", count: 2) # Cost and Total

    expect(page).to have_content_i("Ordered Date\n#{I18n.l(2.days.ago.to_date, format: :usa)}")
  end

  it "can set a reference ID" do
    visit facility_path(facility)
    click_link product.name
    click_link "Add to cart"
    choose account.to_s
    click_button "Continue"

    fill_in "Reference ID", with: "Ref123"
    click_button "Purchase"
    expect(OrderDetail.last.reference_id).to eq("Ref123")
  end
end
