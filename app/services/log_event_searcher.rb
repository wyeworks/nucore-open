# frozen_string_literal: true

class LogEventSearcher

  ALLOWED_EVENTS = ["account.create", "account.update",
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
                    ].freeze

  def self.beginning_of_time
    10.years.ago
  end

  attr_accessor :start_date, :end_date, :events, :query

  def initialize(start_date: nil, end_date: nil, events: [], query: nil)
    @start_date = start_date
    @end_date = end_date
    @events = filter_events(events)
    @query = query
  end

  def filter_events(events)
    Array(events).select { |event| event.in?(ALLOWED_EVENTS) }
  end

  def search
    result = LogEvent.all
    result = result.merge(filter_date) if start_date || end_date
    result = result.merge(filter_event) if events.present?
    result = result.merge(filter_query) if query.present?
    result
  end

  def dates
    [(start_date || LogEventSearcher.beginning_of_time), (end_date || Date.current)]
  end

  def filter_date
    LogEvent.where(event_time: (dates.min.beginning_of_day..dates.max.end_of_day))
  end

  # The event name comes in as <loggable_type>.<event_type>
  def filter_event
    events.flatten.map do |event|
      loggable_type, event_type = event.split(".")
      LogEvent.where(loggable_type: loggable_type.camelize, event_type: event_type)
    end.inject(&:or)
  end

  def filter_query
    accounts = Account.where(Account.arel_table[:account_number].lower.matches("%#{query.downcase}%"))
    users = UserFinder.search(query).unscope(:order)
    account_users = AccountUser.where(account_id: accounts).or(AccountUser.where(user_id: users))
    journals = Journal.where(id: query)
    statements = Statement.where_invoice_number(query).unscope(:order)
    facilities = Facility.name_query(query)
    user_roles = UserRole.with_deleted.where(user_id: users).or(UserRole.with_deleted.where(facility_id: facilities))
    order_details = OrderDetail.where_order_number(query)
    products = Product.where(Product.arel_table[:name].lower.matches("%#{query.downcase}%"))
    product_users = ProductUser.with_deleted.where(product_id: products).or(ProductUser.with_deleted.where(user_id: users))
    [
      accounts,
      users,
      account_users,
      journals,
      statements,
      user_roles,
      order_details,
      products,
      product_users,
    ].compact.map do |filter|
      LogEvent.where(loggable_type: filter.model.name, loggable_id: filter)
    end.inject(&:or)
  end

end
