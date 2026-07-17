# frozen_string_literal: true

module BulkEmail

  module ApplicationHelper

    include Rails.application.routes.url_helpers

    def admin_instrument_send_mail_path(instrument)
      facility_bulk_email_path(
        bulk_email: { user_types: ["customers"] },
        products: [instrument.id],
        start_date: Date.today,
        end_date: 7.days.from_now.to_date,
        return_path: facility_instrument_schedule_path(current_facility, instrument),
        product_id: instrument.id,
      )
    end

    def bulk_email_cancel_params
      bulk_email_recipient_search_params.merge(return_path: params[:return_path])
    end

    def bulk_email_cancel_path
      if bulk_email_cancel_params.present?
        facility_bulk_email_path(bulk_email_cancel_params)
      else
        facility_bulk_email_path
      end
    end

    def bulk_email_recipient_search_params
      QuietStrongParams.with_dropped_params do
        params.permit(:start_date,
                      :end_date,
                      :product_id,
                      :facility_id,
                      products: [],
                      facilities: [],
                      bulk_email: { user_types: [] })
      end
    end

    def date_range_selection_link(translation_key, _params, start_date: Date.today, end_date: Date.today)
      start_date = start_date.to_date
      end_date = end_date.to_date

      link_to(
        text(translation_key, scope: "bulk_email.dates.range"),
        request.query_parameters.merge(start_date: start_date, end_date: end_date),
        class: "js--bulk-email-date-range-selector",
        data: { start_date: start_date, end_date: end_date },
      )
    end

  end

end
