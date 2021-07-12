# frozen_string_literal: true

require "csv"

module UmassCorum

  module AdminReports

    class RelayCsvReport
      include TextHelpers::Translation

      def to_csv
        CSV.generate do |csv|
          csv << headers
          Relay.all.each do |relay|
            csv << build_row(relay)
          end
        end
      end

      def filename
        "instrument_relay_data.csv"
      end

      def description
        text(".subject")
      end

      def text_content
        text(".body")
      end

      def has_attachment?
        true
      end

      def translation_scope
        "views.umass_corum.admin_reports.relays"
      end

      private

      def headers
        [
          text(".facility_name"),
          text(".instrument_name"),
          text(".instrument_active"),
          text(".relay_type"),
          text(".relay_ip_address"),
          text(".relay_ip_port"),
          text(".relay_outlet_number"),
          text(".relay_auto_logout"),
        ]
      end

      def build_row(relay)
        instrument = relay.instrument
        [
          instrument.facility,
          instrument.name,
          instrument_status(instrument),
          relay.type,
          relay.ip,
          relay.ip_port,
          relay.outlet,
          auto_logout_minutes(relay),
        ]
      end

      def instrument_status(instrument)
        instrument.is_archived? ? "Inactive" : "Active"
      end

      def auto_logout_minutes(relay)
        relay.auto_logout ? relay.auto_logout_minutes : "None"
      end
    end

  end

end
