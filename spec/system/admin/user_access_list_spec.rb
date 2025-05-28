# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User access list" do
  describe "as facility director" do
    let(:facility) { create(:setup_facility) }
    let(:admin) { create(:user, :facility_administrator, facility:) }
    let(:user) { create(:user) }
    let!(:product1) { create(:item, facility:, requires_approval: true) }
    let!(:product2) { create(:item, facility:, requires_approval: true) }
    let!(:product_user) { create(:product_user, user:, product: product1)}

    it "can approve access to a product and logs it" do
      expect(user.reload.products).to contain_exactly(product1)

      login_as admin
      visit facility_user_path(facility, user)
      click_on "Access List"
      expect(page).to have_content("Date Added")
      expect(page).to have_content(product_user.approved_at.strftime("%m/%d/%Y"))
      uncheck product1.name
      check product2.name
      click_button "Update Access List"

      expect(user.reload.products).to contain_exactly(product2)

      expect(LogEvent.find_by(loggable: product_user, event_type: :delete, user: admin)).to be_present
      product_user2 = ProductUser.find_by(product: product2, user:)
      expect(LogEvent.find_by(loggable: product_user2, event_type: :create, user: admin)).to be_present
    end

    it "doesn't log anything if nothing changes" do
      login_as admin
      visit facility_user_path(facility, user)
      click_on "Access List"

      expect do
        click_button "Update Access List"
      end.not_to change(LogEvent, :count)
    end

    context "when there's a hidden product" do
      before do
        product1.update(is_archived: false, is_hidden: true)

        login_as admin
      end

      it "shows them" do
        visit facility_user_access_list_path(facility, user)

        within("table") do
          expect(page).to have_content(product1.name)
          expect(page).to have_content(product2.name)
        end
      end
    end

    context "describe inactive product filter" do
      before do
        login_as admin

        product1.update(is_archived: true)
      end

      it "can show inactive products", :js do
        visit facility_user_access_list_path(facility, user)

        within("table") do
          expect(page).to_not have_content("#{product1.name} (inactive)")
          expect(page).to have_content(product2.name)
        end

        # Toggle show inactive
        check("Show inactive Products")

        within("table") do
          expect(page).to have_content("#{product1.name} (inactive)")
          expect(page).to have_content(product2.name)
        end

        # Toggle show again
        uncheck("Show inactive Products")

        within("table") do
          expect(page).to_not have_content("#{product1.name} (inactive)")
        end
      end
    end
  end
end
