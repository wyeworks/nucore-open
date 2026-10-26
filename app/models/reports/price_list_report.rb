# frozen_string_literal: true

module Reports

  class PriceListReport

    include Reports::CsvExporter

    RATE_PRECISION = 2

    PRODUCT_COLUMNS = %i[facility product_type name].freeze

    RATE_COLUMNS = %i[
      unit_cost
      usage_rate
      minimum_cost
      cancellation_cost
      daily_rate
      step_1_start
      step_1_rate
      step_2_start
      step_2_rate
      step_3_start
      step_3_rate
    ].freeze

    PRICE_POLICY_ATTRIBUTES = {
      unit_cost: :unit_cost,
      usage_rate: :hourly_usage_rate,
      minimum_cost: :minimum_cost,
      cancellation_cost: :cancellation_cost,
      daily_rate: :usage_rate_daily,
    }.freeze

    STEP_COLUMNS = {
      step_1_start: [0, :start],
      step_1_rate: [0, :rate],
      step_2_start: [1, :start],
      step_2_rate: [1, :rate],
      step_3_start: [2, :start],
      step_3_rate: [2, :rate],
    }.freeze

    def self.filters
      [:fiscal_year]
    end

    def initialize(fiscal_year: nil)
      @fiscal_year = Integer(fiscal_year.to_s, exception: false) || SettingsHelper.fiscal_year_end.year
    end

    attr_reader :fiscal_year

    def report_data_query
      Product.not_archived
             .where.not(type: "Bundle")
             .joins(:facility)
             .includes(:facility)
             .order("facilities.name", "products.name")
    end

    def default_report_hash
      product_report_hash.merge(price_group_report_hash)
    end

    def column_headers
      product_headers + price_group_headers
    end

    def filename
      "price_list_fy#{fiscal_year}.csv"
    end

    def description
      text(".subject", fiscal_year:)
    end

    protected

    def translation_scope
      "reports.price_list"
    end

    private

    def product_report_hash
      {
        facility: ->(product) { product.facility.to_s },
        product_type: ->(product) { product.class.model_name.human },
        name: :name,
      }
    end

    def price_group_report_hash
      price_groups.each_with_object({}) do |price_group, columns|
        RATE_COLUMNS.each do |column|
          columns[column_key(price_group, column)] = ->(product) { rate_for(product, price_group, column) }
        end
      end
    end

    def product_headers
      PRODUCT_COLUMNS.map { |column| header_for(column, product_header_default(column)) }
    end

    def price_group_headers
      price_groups.flat_map do |price_group|
        RATE_COLUMNS.map { |column| "#{price_group_label(price_group)} - #{header_for(column, rate_header_default(column))}" }
      end
    end

    def price_group_label(price_group)
      return price_group.name if price_group.facility.nil?

      "#{price_group.name} (#{price_group.facility.abbreviation})"
    end

    def header_for(column, default)
      text(".headers.#{column}", default:)
    end

    def product_header_default(column)
      case column
      when :facility then Facility.model_name.human
      when :name then Product.model_name.human
      else column.to_s.titleize
      end
    end

    def rate_header_default(column)
      attribute = PRICE_POLICY_ATTRIBUTES[column]
      attribute ? PricePolicy.human_attribute_name(attribute) : column.to_s.titleize
    end

    def column_key(price_group, column)
      :"price_group_#{price_group.id}_#{column}"
    end

    def price_groups
      @price_groups ||= PriceGroup.ordered_with_subsidies(PriceGroup.visible.includes(:facility).to_a)
    end

    def fiscal_year_beginning
      @fiscal_year_beginning ||= SettingsHelper.fiscal_year(fiscal_year - 1)
    end

    def fiscal_year_end
      @fiscal_year_end ||= SettingsHelper.fiscal_year_end(fiscal_year_beginning)
    end

    def policies
      @policies ||= PricePolicy
                    .where(product_id: report_data.map(&:id))
                    .where("start_date <= ? AND expire_date >= ?", fiscal_year_end, fiscal_year_beginning)
                    .includes(:duration_rates)
                    .order(:start_date, :id)
                    .index_by do |policy|
                      [policy.product_id, policy.price_group_id]
                    end
    end

    def policy_for(product, price_group)
      policy = policies[[product.id, price_group.id]]
      policy if policy&.can_purchase?
    end

    def rate_for(product, price_group, column)
      policy = policy_for(product, price_group)
      return if policy.nil?

      value = case column
              when :unit_cost then unit_cost(policy)
              when :usage_rate then usage_rate(policy)
              when :minimum_cost then minimum_cost(policy)
              when :cancellation_cost then cancellation_cost(policy)
              when :daily_rate then daily_rate(policy)
              else duration_step(product, policy, column)
              end

      value.is_a?(Numeric) ? value.round(RATE_PRECISION) : value
    end

    def unit_cost(policy)
      policy.unit_total if policy.respond_to?(:unit_total)
    end

    def usage_rate(policy)
      return unless policy.respond_to?(:has_rate?) && policy.has_rate?

      policy.subsidized_hourly_usage_cost
    end

    def minimum_cost(policy)
      return unless policy.respond_to?(:has_minimum_cost?) && policy.has_minimum_cost?

      policy.has_rate? ? policy.subsidized_minimum_cost : policy.minimum_cost
    end

    def cancellation_cost(policy)
      return unless policy.respond_to?(:charge_full_price_on_cancellation?)
      return PricePolicy.human_attribute_name(:full_price_cancellation) if policy.charge_full_price_on_cancellation?

      policy.cancellation_cost
    end

    def daily_rate(policy)
      return unless policy.respond_to?(:has_daily_rate?) && policy.has_daily_rate?

      policy.subsidized_daily_usage_cost
    end

    def duration_step(product, policy, column)
      return unless product.duration_pricing_mode?

      index, field = STEP_COLUMNS.fetch(column)
      duration_rate = sorted_duration_rates(policy)[index]
      return if duration_rate.nil?

      field == :start ? duration_rate.min_duration_hours : step_rate(duration_rate)
    end

    def step_rate(duration_rate)
      duration_rate.subsidy.present? ? duration_rate.subsidized_hourly_cost : duration_rate.hourly_rate
    end

    def sorted_duration_rates(policy)
      @sorted_duration_rates ||= {}
      @sorted_duration_rates[policy.id] ||= policy.duration_rates.sort_by(&:min_duration_hours)
    end

  end

end
