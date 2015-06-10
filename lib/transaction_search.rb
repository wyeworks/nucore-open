module TransactionSearch
  DATE_RANGE_FIELDS = [['Ordered', 'ordered_at'],
                       ['Fulfilled', 'fulfilled_at'],
                       ['Journaled/Statement', 'journal_or_statement_date']
                      ]

  def self.included(base)
    base.extend(ClassMethods)
    base.helper NUCore::Database::RelationHelper
  end

  module ClassMethods
    def transaction_search(*actions)
      self.before_filter :remove_ugly_params_and_redirect, :only => actions
    end

    # If a method is tagged with _with_search at the end, then define the normal controller
    # action to be wrapped in the search.
    # e.g. index_with_search will define #index, which will init_order_details before passing
    # control to the controller method. Then it will further filter @order_details after the controller
    # method has run
    def method_added(name)
      @@methods_with_remove_ugly_filter ||= []
      if (name.to_s =~ /(.*)_with_search$/)
        @@methods_with_remove_ugly_filter << $1
        self.before_filter :remove_ugly_params_and_redirect, :only => @@methods_with_remove_ugly_filter
        define_search_method($1, $&)
      end
    end

    private

    def define_search_method(new_method_name, old_method_name)
      define_method(new_method_name) do
        init_order_details
        send(:"#{old_method_name}")
        load_search_options
        @empty_orders = @order_details.empty?
        # simple_form will wrap in :transactions object
        @search_fields = params[:transactions] || params
        do_search(@search_fields)
        add_optimizations
        sort_and_paginate
        email_raw_export(params[:to_email], account_transaction_report) if params[:to_email]
        respond_to do |format|
          format.html { render layout: @layout if @layout }
          format.csv { render text: account_transaction_report.to_csv }
        end
      end
    end
  end

  def order_by_desc
    field = @date_range_field
    if @date_range_field.to_sym == :journal_or_statement_date
      field = "COALESCE(journal_date, in_range_statements.created_at)"
    end
    @order_details.order_by_desc_nulls_first(field)
  end

  def init_order_details
    @order_details = OrderDetail.joins(:order).joins(:product).ordered

    if current_facility
      @order_details = @order_details.for_facility(current_facility)
    end

    @order_details = @order_details.where(:account_id => @account.id) if @account
  end

  # Find all the unique search options based on @order_details. This needs to happen before do_search so these
  # variables have the full non-searched section of values
  def load_search_options
    @facilities = Facility.find_by_sql(@order_details.joins(:order => :facility).
                                                      select("distinct(facilities.id), facilities.name, facilities.abbreviation").
                                                      reorder("facilities.name").to_sql)

    @accounts = Account.find_by_sql(@order_details.joins(:account).
                                                   select("distinct(accounts.id), accounts.description, accounts.account_number, accounts.type").
                                                   reorder("accounts.account_number, accounts.description").to_sql)
    @products = Product.find_by_sql(@order_details.joins(:product).
                                                   select("distinct(products.id), products.name, products.facility_id, products.type, products.requires_approval").
                                                   reorder("products.name").to_sql)
    @account_owners = User.find_by_sql(@order_details.joins(:account => {:owner => :user}).
                                                      select("distinct(users.id), users.first_name, users.last_name").
                                                      reorder("users.last_name, users.first_name").to_sql)

    @order_statuses = OrderStatus.find_by_sql(@order_details.joins(:order_status).
                                                             select("distinct(order_statuses.id), order_statuses.facility_id, order_statuses.name, order_statuses.lft").
                                                             reorder("order_statuses.lft").to_sql)

  end

  def paginate_order_details(per_page = nil)
    @per_page = per_page if per_page.present?
    @paginate_order_details = true
  end

  def order_details_sort(field)
    @order_details_sort = field
  end

  private

  def do_search(search_params)
    #Rails.logger.debug "search: #{search_params}"
    @order_details = @order_details || OrderDetail.joins(:order).ordered
    @order_details = @order_details.for_accounts(search_params[:accounts])
    @order_details = @order_details.for_products(search_params[:products])
    @order_details = @order_details.for_owners(search_params[:account_owners])
    @order_details = @order_details.for_order_statuses(search_params[:order_statuses])
    start_date = parse_usa_date(search_params[:start_date].to_s.gsub("-", "/"))
    end_date = parse_usa_date(search_params[:end_date].to_s.gsub("-", "/"))

    @order_details = @order_details.for_facilities(search_params[:facilities])
    @date_range_field = date_range_field(search_params[:date_range_field])
    @order_details = @order_details.action_in_date_range(@date_range_field, start_date, end_date)
  end

  def add_optimizations
    # cut down on some n+1s
    @order_details = @order_details.
        includes(:order => :facility).
        includes(:account).
        preload(:product).
        preload(:order_status).
        includes(:reservation).
        includes(:order => :user).
        includes(:price_policy).
        preload(:bundle)
  end

  def sort_and_paginate
    @order_details = @order_details_sort ? @order_details.reorder(@order_details_sort) : order_by_desc
    @order_details = @order_details.paginate(pagination_args) if @paginate_order_details
  end

  private

  def pagination_args
    args = { page: params[:page] }
    args[:per_page] = @per_page if @per_page.present?
    args
  end

  def date_range_field(field)
    whitelist = TransactionSearch::DATE_RANGE_FIELDS.map(&:last)
    whitelist.include?(field) ? field : 'fulfilled_at'
  end

  def account_transaction_report
    Reports::AccountTransactionsReport.new(@order_details, date_range_field: @date_range_field)
  end

  def email_raw_export(to_email, report)
    AccountTransactionReportMailer.delay.csv_report_email(to_email, @order_details.map(&:id), @date_range_field)
  end
end
