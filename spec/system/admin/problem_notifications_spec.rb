# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Problem Notifications", :js do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:order) { create(:purchased_order, product: item) }
  let(:order_detail) { order.order_details.first }

  before do
    order_detail.update!(price_policy: nil, state: "complete", problem: true) # Make it a problem order
    login_as director
  end

  describe "bulk notification feature" do
    before do
      visit show_problems_facility_orders_path(facility)
    end

    it "shows the notification form with checkboxes" do
      expect(page).to have_css("input[value='Send Reminders']")
      expect(page).to have_content("Resolvable users")
      expect(page).to have_content("Non-resolvable users")
      expect(page).to have_css("input[name='order_detail_ids[]']")
      expect(page).to have_css("input[name='notification_groups[]']")
    end

    it "enables submit button when both orders and groups are selected" do
      submit_button = find("input[value='Send Reminders']")
      expect(submit_button).to be_disabled

      # Select a notification group
      check "Resolvable users"
      expect(submit_button).to be_disabled

      uncheck "Resolvable users"

      # Select an order
      first("input[name='order_detail_ids[]']").check
      expect(submit_button).to be_disabled

      check "Resolvable users"
      expect(submit_button).not_to be_disabled
    end

    it "shows confirmation dialog when submitting" do
      first("input[name='order_detail_ids[]']").check
      check "Resolvable users"

      accept_confirm do
        click_button "Send Reminders"
      end

      expect(page).to have_content("Successfully sent")
    end

    it "allows selecting multiple orders and groups" do
      another_order = create(:purchased_order, product: item)
      another_order.order_details.first.update!(price_policy: nil, state: "complete", problem: true)

      visit show_problems_facility_orders_path(facility)

      all("input[name='order_detail_ids[]']").each(&:check)
      check "Resolvable users"
      check "Non-resolvable users"

      accept_confirm do
        click_button "Send Reminders"
      end

      expect(page).to have_content("Successfully sent")
    end
  end
end
