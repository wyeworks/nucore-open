# frozen_string_literal: true

module Reports

  class LogEventsReport

    include Reports::CsvExporter

    ALLOWED_EVENTS = [
      "account.create", "account.update",
      "account_user.create", "account_user.delete",
      "user.create", "user.suspended", "user.unsuspended",
      "user.default_price_group_changed",
      "account.suspended", "account.unsuspended",
      "journal.create", "statement.create",
      "user_role.create", "user_role.delete",
      "order_detail.dispute", "order_detail.resolve",
      "order_detail.notify", "order_detail.review",
      "order_detail.problem_queue", "order_detail.price_change",
      "order_detail.resolve_from_problem_queue",
      "product_user.create", "product_user.delete",
      "price_group_member.create", "price_group_member.delete",
      "facility.activate", "facility.deactivate",
      "price_group.create", "price_group.delete",
      "product.activate", "product.deactivate",
      "product.create", "relay.update",
      "order_import.created",
    ].freeze

    def initialize(start_date:, end_date:, events:, query:)
      @start_date = start_date
      @end_date = end_date
      @events = whitelist_events(events)
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
      LogEventSearcher.new(
        relation: LogEvent.non_billing_type,
        start_date: @start_date,
        end_date: @end_date,
        events: @events,
        query: @query,
      ).search.includes(:user, :loggable).reverse_chronological
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

    def whitelist_events(events)
      Array(events).select { |event| event.in?(ALLOWED_EVENTS) }
    end

  end

end
