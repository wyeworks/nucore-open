# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Problem Notifications", :js do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:instrument) { create(:setup_instrument, :timer, facility: facility, problems_resolvable_by_user: true) }
  let(:reservation) { create(:purchased_reservation, product: instrument, actual_start_at: 1.hour.ago, actual_end_at: nil) }
  let(:order_detail) { reservation.order_detail }

  before do
    order_detail.update!(price_policy: nil) # Make it a problem order
    sign_in director
  end

  describe "bulk notification feature" do
    before do
      visit show_problems_facility_orders_path(facility)
    end

    it "shows the notification form with checkboxes" do
      expect(page).to have_content("Send Reminders")
      expect(page).to have_content("Users who can resolve problems")
      expect(page).to have_content("Users who need to contact facility")
      expect(page).to have_css("input[name='order_detail_ids[]']")
      expect(page).to have_css("input[name='notification_groups[]']")
    end

    it "enables submit button when both orders and groups are selected" do
      submit_button = find("input[value='Send Reminders']")
      expect(submit_button).to be_disabled

      # Select an order
      first("input[name='order_detail_ids[]']").check
      expect(submit_button).to be_disabled

      # Select a notification group
      first("input[name='notification_groups[]']").check
      expect(submit_button).not_to be_disabled
    end

    it "shows confirmation dialog when submitting" do
      first("input[name='order_detail_ids[]']").check
      first("input[name='notification_groups[]']").check

      accept_confirm do
        click_button "Send Reminders"
      end

      expect(page).to have_content("Successfully sent")
    end

    it "allows selecting multiple orders and groups" do
      another_reservation = create(:purchased_reservation, product: instrument, actual_start_at: 1.hour.ago, actual_end_at: nil)
      another_reservation.order_detail.update!(price_policy: nil)

      visit show_problems_facility_orders_path(facility)

      all("input[name='order_detail_ids[]']").each(&:check)
      all("input[name='notification_groups[]']").each(&:check)

      accept_confirm do
        click_button "Send Reminders"
      end

      expect(page).to have_content("Successfully sent")
    end

    it "shows error when no orders are selected" do
      first("input[name='notification_groups[]']").check

      click_button "Send Reminders"

      expect(page).to have_content("Please select at least one order")
    end

    it "shows error when no notification groups are selected" do
      first("input[name='order_detail_ids[]']").check

      click_button "Send Reminders"

      expect(page).to have_content("Please select at least one notification group")
    end
  end
end
