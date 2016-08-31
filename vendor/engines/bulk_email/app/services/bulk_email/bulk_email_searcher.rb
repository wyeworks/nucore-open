module BulkEmail

  class BulkEmailSearcher

    include DateHelper

    attr_reader :order_details, :search_fields

    DEFAULT_SORT = [:last_name, :first_name].freeze
    USER_TYPES = %i(customers authorized_users account_owners).freeze

    def initialize(search_fields)
      @search_fields = search_fields
    end

    def user_types
      @user_types ||=
        USER_TYPES & (search_fields[:bulk_email][:user_types] || []).map(&:to_sym)
    end

    def do_search
      return [] if user_types.blank?
      user_types.map do |user_type|
        public_send(:"search_#{user_type}")
      end.sum
    end

    def search_customers
      order_details = find_order_details.joins(order: :user)
      users.find_by_sql(order_details.select("distinct(users.id), users.*")
                                            .reorder("users.last_name, users.first_name")
                                            .merge(users)
                                            .to_sql)
    end

    def search_account_owners
      order_details = find_order_details_for_roles([AccountUser::ACCOUNT_OWNER])
      User.find_by_sql(order_details.joins(account: { account_users: :user })
                                     .select("distinct(users.id), users.*")
                                     .reorder("users.last_name, users.first_name")
                                     .merge(users)
                                     .to_sql)
    end

    def search_authorized_users
      result = users.joins(:product_users).uniq
      # if we don't have any products, listed get them all for the current facility
      product_ids = search_fields[:products].presence || Facility.find(search_fields[:facility_id]).products.map(&:id)
      result.where(product_users: { product_id: product_ids }).reorder(*self.class::DEFAULT_SORT)
    end

    private

    def users
      User.active
    end

    def find_order_details
      order_details = OrderDetail.for_products(search_fields[:products])
                                 .joins(:order)
                                 .where(orders: { facility_id: search_fields[:facility_id] })

      @order_details = order_details.ordered_or_reserved_in_range(start_date, end_date)
    end

    def find_order_details_for_roles(roles)
      find_order_details.joins(account: :account_users).where(account_users: { user_role: roles })
    end

    def start_date
      parse_usa_date(search_fields[:bulk_email][:start_date].to_s.tr("-", "/")) if search_fields[:bulk_email][:start_date]
    end

    def end_date
      parse_usa_date(search_fields[:bulk_email][:end_date].to_s.tr("-", "/")) if search_fields[:bulk_email][:end_date]
    end

  end

end
