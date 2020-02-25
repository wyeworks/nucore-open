require "rails_helper"

RSpec.describe "ProductDisplayGroups" do
  let(:facility) { create(:setup_facility) }
  let!(:items) { create_list(:item, 2, facility: facility) }

  describe "as a director" do
    let(:director) { create(:user, :facility_director, facility: facility) }

    before do
      login_as director
    end

    it "can create a new display group" do
      visit facility_products_path(facility)
      click_link "Product Groups"
      click_link "Add Product Group"
      fill_in "Name", with: "My new group"
      select items.first.name, from: "Products"
      click_button "Create Product Group"
      expect(page).to have_content("My new group")

      expect(ProductDisplayGroup.last.products).to eq([items.first])
    end

    it "renders an error when trying to add a product that already is grouped" do
      visit new_facility_product_display_group_path(facility)

      # As if it were added in another tab
      other_group = create(:product_display_group, facility: facility)
      other_group.products << items.first

      select items.first.name, from: "Products"
      click_button "Create Product Group"

      expect(page).to have_content("is already in a group")
    end

    describe "editing" do
      let!(:display_group) { create(:product_display_group, name: "My group", facility: facility, products: items.take(1)) }

      it "can edit the group's name" do
        visit facility_products_path(facility)
        click_link "Product Groups"
        click_link "Edit"
        expect(page).to have_field("Name", with: "My group")
        fill_in "Name", with: "New Name"
        click_button "Update Product Group"
        expect(page).to have_content("New Name")
      end

      it "can swap items without javascript" do
        expect(display_group.products).to eq([items.first])

        visit edit_facility_product_display_group_path(facility, display_group)
        unselect items.first.name, from: "Products"
        select items.second.name, from: "Products"
        click_button "Update Product Group"

        expect(display_group.reload.products).to eq([items.second])
      end

      it "can swap items with javascript", :js do
        visit edit_facility_product_display_group_path(facility, display_group)
        expect(page).to have_select("Products", options: [items.first.name])
        expect(page).to have_select("Ungrouped", options: [items.second.name])

        select items.second.name, from: "Ungrouped"
        click_link "Include"

        select items.first.name, from: "Products"
        # This unselection happens on a normal click in the browser, but capybara
        # seems to do a "shift-click" on the `select`.
        unselect items.second.name, from: "Products"
        click_link "Exclude"

        click_button "Update Product Group"

        expect(display_group.reload.products).to eq([items.second])
      end

      it "renders an error when trying to add a product that already is grouped" do
        visit edit_facility_product_display_group_path(facility, display_group)

        # As if it were done in another tab
        other_group = create(:product_display_group, facility: facility)
        other_group.products << items.second

        select items.second.name, from: "Products"
        click_button "Update Product Group"

        expect(page).to have_content("is already in a group")
      end
    end

    describe "destroy" do
      let!(:display_group) { create(:product_display_group, name: "My group", facility: facility, products: [product]) }
      let(:product) { create(:item, facility: facility) }

      it "can remove the group and makes the product ungrouped" do
        visit facility_products_path(facility)
        click_link "Product Groups"
        click_link "Edit"
        click_link "Delete"
        expect(page).not_to have_content("My group")
        expect(product.reload.product_display_group).to be_blank
      end
    end

    describe "re-ordering" do
      let!(:display_group) { create(:product_display_group, name: "First", position: 0, facility: facility) }
      let!(:display_group2) { create(:product_display_group, name: "Second", position: 1, facility: facility) }

      it "can reorder the groups", :js do
        visit facility_product_display_groups_path(facility)
        click_link "Reorder Product Groups"
        select "Second", from: "Product Groups"
        find("[title='Move Up']").click
        click_button "Update Ordering"

        expect(facility.reload.product_display_groups.sorted).to eq([display_group2, display_group])
      end
    end
  end

  describe "as facility staff" do
    let(:staff) { create(:user, :staff, facility: facility) }
    let!(:display_group) { create(:product_display_group, name: "My group", facility: facility) }
    before do
      login_as staff
    end

    it "can view the index page, but not add or edit the groups" do
      visit facility_products_path(facility)
      click_link "Product Groups"
      expect(page).to have_content("My group")
      expect(page).not_to have_link("Edit")
      expect(page).not_to have_link("Add Product Group")
    end

    it "can't directly access the new or edit page", :aggregate_failures do
      visit new_facility_product_display_group_path(facility)
      expect(page.status_code).to eq(403)

      visit edit_facility_product_display_group_path(facility, display_group)
      expect(page.status_code).to eq(403)
    end
  end

end
