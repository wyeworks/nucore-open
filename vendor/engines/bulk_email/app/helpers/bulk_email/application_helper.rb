module BulkEmail

  module ApplicationHelper

    include Rails.application.routes.url_helpers

    def admin_instrument_send_mail_path(instrument)
      facility_bulk_email_path(
        bulk_email: { user_types: ["customers"] },
        products: [instrument.id],
        start_date: l(Date.today, format: :usa),
        end_date: l(7.days.from_now.to_date, format: :usa),
        return_path: facility_instrument_schedule_path(current_facility, instrument),
        default_text: instrument_mail_default_text(instrument),
      )
    end

    private

    def instrument_mail_default_text(instrument)
      return "" if instrument.online?
      instrument.offline_reservations.last.reason_statement
    end

  end

end
