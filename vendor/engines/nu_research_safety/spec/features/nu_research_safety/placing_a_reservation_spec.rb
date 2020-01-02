# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Placing a reservation with a certification requirement" do
  let!(:instrument) { FactoryBot.create(:setup_instrument) }
  let(:facility) { instrument.facility }
  let!(:cert1) { create(:product_certification_requirement, product: instrument).certificate }
  let!(:cert2) { create(:product_certification_requirement, product: instrument).certificate }
  let(:user) { create(:user) }
  let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let!(:account_price_group_member) do
    create(
      :account_price_group_member,
      account: account,
      price_group: instrument.price_policies.first.price_group,
    )
  end

  describe "as the user" do
    before do
      login_as user
      visit facility_path(facility)
      click_link instrument.name
    end

    context "who does not have their certifications" do
      before do
        allow(NuResearchSafety::CertificationLookup).to receive(:certified?).and_return(false)
      end

      it "displays an error on the page" do
        click_button "Create"

        expect(page).to have_content "Missing Certificates: #{cert1.name}, #{cert2.name}"
      end
    end

    context "who does have their certifications" do
      before do
        allow(NuResearchSafety::CertificationLookup).to receive(:certified?).and_return(true)
      end

      it "saves the reservation and brings you back to My Reservations" do
        click_button "Create"

        expect(page).to have_content "My Reservations"
      end
    end

    describe "ordering on behalf, and the user does not have certifications" do
      let(:facility_staff) { create(:user, :staff, facility: facility) }

      before do
        login_as facility_staff
        visit facility_users_path(facility)
        fill_in "search_term", with: user.email
        click_button "Search"
        click_link "Order For"

        click_link instrument.name
      end

      it "it saves the reservation" do
        click_button "Create"

        expect(page).to have_content "The reservation was successfully created"
      end
    end
  end
end
