# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Order show" do
  let(:facility) { create(:setup_facility) }
  let(:account) { create(:setup_account) }
  let!(:instrument) { create(:setup_instrument, :always_available, :daily_booking, facility:) }
  let(:reservation_order) { create(:setup_order, product: instrument, account:) }
  let!(:reservation) do
    create(
      :purchased_reservation,
      product: instrument,
      order_detail: reservation_order.order_details.first,
      reserve_start_at: 1.day.from_now,
      reserve_end_at: 4.days.from_now
    )
  end
  let(:facility_administrator) { create(:user, :facility_administrator, facility:) }

  before do
    login_as facility_administrator
    visit facility_order_path(facility, reservation_order)
  end

  describe "reservation duration" do
    it "is correctly displayed in days" do
      # Reserved is the third column
      expect(all("tbody tr").first.all("td")[2]).to have_text("3", exact: true)
    end
  end

  describe "reservation actual" do
    it "is correctly displayed in days" do
      # Actual is the fourth column
      expect(all("tbody tr").first.all("td")[3]).to have_text("0", exact: true)
    end
  end

  describe "manage modal", :js do
    before do
      click_link(reservation_order.order_details.first.to_s)
      wait_for_ajax
    end

    it "shows the duration days field" do
      expect(page).to have_field("Duration Days", with: "3")
    end
  end
end
