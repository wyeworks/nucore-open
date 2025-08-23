# frozen_string_literal: true

class LogEventSearcher

  def self.beginning_of_time
    10.years.ago
  end

  attr_accessor :relation, :start_date, :end_date, :events, :query, :invoice_number, :payment_source

  def initialize(relation: LogEvent.all, **options)
    @relation = relation
    @start_date = options[:start_date]
    @end_date = options[:end_date]
    @events = options[:events] || []
    @query = options[:query]
    @invoice_number = options[:invoice_number]
    @payment_source = options[:payment_source]
  end

  def search
    result = relation
    result = relation.merge(filter_date) if start_date || end_date
    result = result.merge(filter_event) if events.present?
    result = result.merge(filter_query) if query.present?

    if invoice_number.present? || payment_source.present?
      result = result.merge(filter_statements)
    end

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
    LogEvent.with_events(events)
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

  def filter_statements
    statements = Statement.all

    if invoice_number.present?
      query = if Nucore::Database.oracle?
                "TO_CHAR(statements.id) LIKE :invoice_number OR account_id || '-' || id LIKE :invoice_number"
              else
                "CAST(statements.id AS CHAR) LIKE :invoice_number OR CONCAT(account_id, '-', id) LIKE :invoice_number"
              end
      statements = statements.where(query, invoice_number: "%#{invoice_number}%")
    end

    if payment_source.present?
      matching_accounts = Account
                          .where("account_number LIKE :payment_source OR description LIKE :payment_source",
                                 payment_source: "%#{payment_source}%")

      statements = statements.where(account_id: matching_accounts.select(:id))
    end

    LogEvent.where(loggable_type: "Statement", loggable_id: statements.unscope(:order))
  end

end
