module Reports
  class LogEventsReport

    include Reports::CsvExporter

    def initialize(start_date:, end_date:, events:, query:)
      @start_date = start_date
      @end_date = end_date
      @events = events
      @query = query
    end

    def default_report_hash
      {
        event_time: :created_at,
        event: ->(log_event) { text(log_event.locale_tag, log_event.metadata.symbolize_keys) },
        object: ->(log_event) { log_event.loggable_to_s },
        facility: ->(log_event) { log_event.facility },
        user: :user,
      }
    end

    def log_events
      LogEvent.search(
        start_date: @start_date,
        end_date: @end_date,
        events: @events,
        query: @query,
      ).includes(:user, :loggable).reverse_chronological
    end

    def report_data_query
      log_events
    end

    def filename
      "event_log.csv"
    end

    def description
      "Event Log Export #{formatted_date_range}"
    end

    protected

    def translation_scope
      "views.log_events.index"
    end

  end
end
