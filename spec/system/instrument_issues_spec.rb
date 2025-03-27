# frozen_string_literal: true

require "rails_helper"

RSpec.describe do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument, facility: facility) }
  let(:user) { create(:user) }
  let(:order) { create(:setup_order, product: instrument) }
  let!(:facility_director) { create(:user, :facility_director, facility: facility) }

  describe "when logged in" do
    before { login_as user }

    it "triggers an email and sends you to my reservations" do
      visit new_facility_order_order_detail_issue_path(facility, order, order.order_details.first)
      fill_in "Message", with: "A problem"

      expect { click_button "Report Issue" }.to(
        have_enqueued_mail(InstrumentIssueMailer, :create)
      )
      expect(page).to have_content("My Reservations")
    end

    it "does not send the email if missing a field" do
      visit new_facility_order_order_detail_issue_path(facility, order, order.order_details.first)

      expect { click_button "Report Issue" }.not_to have_enqueued_mail
      expect(page).to have_content("can't be blank")
    end
  end

  it "cannot access the page if not logged in" do
    visit new_facility_order_order_detail_issue_path(facility, order, order.order_details.first)
    expect(current_path).to eq(new_user_session_path)
  end
end
