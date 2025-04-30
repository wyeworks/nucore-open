# frozen_string_literal: true

require "rails_helper"

RSpec.describe "email log_events page" do
  let(:some_user) { create(:user, first_name: "Socrates") }
  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_service, facility:) }
  let(:order) { create(:setup_order, product:) }
  let(:order_detail) { order.order_details.first }
  let(:admin) { create(:user, :administrator) }
  let(:statement) { create(:statement, order_details: [order_detail]) }

  let(:email) do
    double(
      "Email",
      to: "random@example.com",
      subject: "Some Subject"
    )
  end

  before do
    [
      [some_user, :review_orders_email],
      [statement, :statement_email],
    ].each do |loggable, event_type|
      LogEvent.log_email(
        loggable,
        event_type,
        email
      )
    end
  end

  describe "email log events filtering" do
    before { login_as create(:user, :administrator) }

    it "filter events by type" do
      visit billing_log_events_path

      select(
        "#{I18n.t('Statement')} Email",
        from: "Event",
      )

      click_button("Filter")

      within("table.table") do
        expect(page).to have_content(I18n.t("Statement"))
        expect(page).to_not have_content("Review Orders")
      end
    end

    context "filter by date" do
      let(:log_event1) { LogEvent.where(event_type: :review_orders_email).first }
      let(:log_event2) { LogEvent.where(event_type: :statement_emails).first }

      before do
        log_event1.update(event_time: 1.week.ago)
      end

      it "filter events by date" do
        visit billing_log_events_path

        fill_in("End Date", with: I18n.l(1.day.ago.to_date, format: :usa))

        click_button("Filter")

        within("table.table") do
          expect(page).to have_content("Review Orders")
          expect(page).to_not have_content(I18n.t("Statement"))
        end
      end
    end
  end
end
