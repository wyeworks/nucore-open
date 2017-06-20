require "rails_helper"

RSpec.describe "Purchasing a reservation" do

  let!(:instrument) { FactoryGirl.create(:setup_instrument, user_notes_field_mode: "optional") }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryGirl.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:account_price_group_member) do
    FactoryGirl.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  before do
    login_as user
    visit root_path
    click_link facility.name
    click_link instrument.name
    select user.accounts.first.description, from: "Payment Source"
  end

  describe "selecting the default time" do
    before do
      fill_in "Note", with: "A note about my reservation"
      click_button "Create"
    end

    it "is on the My Reservations page" do
      expect(page).to have_content "My Reservations"
      expect(page).to have_content "Note: A note about my reservation"
    end
  end

  describe "attempting to order in the past", :time_travel do
    let(:now) { Time.zone.local(2016, 8, 20, 11, 0) }

    before do
      select "10", from: "reservation[reserve_start_hour]"
      select "10", from: "reservation[reserve_end_hour]"
      click_button "Create"
    end

    it "has an error" do
      expect(page).to have_content "must start at a future time"
    end
  end

  describe "trying to order with a required note" do
    before do
      instrument.update!(
        user_notes_field_mode: "required",
        user_notes_label: "Show me what you got",
      )
    end

    it "does not create the reservation without a note" do
      click_button "Create"
      expect(page).to have_content "Note may not be blank"

      fill_in "Show me what you got", with: "This is my note."
      click_button "Create"

      expect(page).to have_content("My Reservations")
    end

  end

end
