# frozen_string_literal: true

RSpec.shared_examples "creates a product with billing mode" do |product_type, billing_mode|
  let(:logged_in_user) { administrator }

  it "can create a #{product_type}, which automatically creates a price rule" do
    visit facility_products_path(facility)
    all("a", text: product_type.capitalize)[0].click
    click_link "Add #{product_type.capitalize}"

    fill_in "Name", with: "My new Product", match: :first
    fill_in "URL Name", with: "new-service"
    select "Required", from: "Users may submit a note when purchasing?"
    select billing_mode, from: "Billing mode"

    click_button "Create"
    expect(Product.last.name).to eq("My new Product")

    click_on "Pricing"
    expect(page).to have_content "#{PriceGroup.nonbillable} (#{PriceGroup.nonbillable.type_string}) $0"
    expect(PricePolicy.last.product.name).to eq("My new Product")
    expect(PricePolicy.last.usage_rate).to eq(nil)
  end
end
