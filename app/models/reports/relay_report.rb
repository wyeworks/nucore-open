# frozen_string_literal: true

module Reports

  class RelayReport

    include Reports::CsvExporter

    def default_report_hash
      {
        facility: ->(relay) { relay.instrument.facility },
        instrument: ->(relay) { relay.instrument.name },
        active: ->(relay) { relay.instrument.is_archived? ? "Inactive" : "Active" },
        type: :type,
        ip: :ip,
        ip_port: :ip_port,
        outlet: :outlet,
        auto_logout_minutes: ->(relay) { relay.auto_logout ? relay.auto_logout_minutes : "None" },
      }
    end

    def report_data_query
      Relay.where.not(type: "RelayDummy")
           .joins(instrument: :facility)
           .includes(instrument: :facility)
           .order("facilities.name", "products.name")
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

    protected

    def translation_scope
      "reports.relay"
    end

  end

end
