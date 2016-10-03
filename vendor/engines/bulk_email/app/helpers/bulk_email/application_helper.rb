module BulkEmail

  module ApplicationHelper

    include Rails.application.routes.url_helpers

    def admin_instrument_send_mail_path(instrument)
      facility_bulk_email_path(
        products: [instrument.id],
        start_date: l(Date.today, format: :usa),
        end_date: l(7.days.from_now.to_date, format: :usa),
      )
    end

  end

end
