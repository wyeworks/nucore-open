# frozen_string_literal: true

# rubocop:disable Style/BarePercentLiterals, Style/RescueModifier, Layout/SpaceInsideStringInterpolation, Style/UnneededPercentQ
module ActiveRecord

  module ConnectionAdapters

    class OracleEnhancedAdapter

      # This method is near-verbatim from https://github.com/rsim/oracle-enhanced/tree/v1.6.7
      # The only difference is under the value.acts_like?(:time) condition to
      # patch a bug where it assumed that no fractional seconds meant the value
      # was a Date, not a Time.
      #
      # Without the patch:
      #
      # [1] pry(main)> ActiveRecord::Base.connection.quote(Time.current.change(usec: 0))
      # => "TO_DATE('2017-01-04 19:40:56','YYYY-MM-DD HH24:MI:SS')"
      # [2] pry(main)> ActiveRecord::Base.connection.quote(Time.current.change(usec: 1))
      # => "TO_TIMESTAMP('2017-01-04 19:40:58:000001','YYYY-MM-DD HH24:MI:SS:FF6')"
      #
      # With the patch:
      #
      # [1] pry(main)> ActiveRecord::Base.connection.quote(Time.current.change(usec: 0))
      # => "TO_TIMESTAMP('2017-01-04 19:41:51:000000','YYYY-MM-DD HH24:MI:SS:FF6')"
      # [2] pry(main)> ActiveRecord::Base.connection.quote(Time.current.change(usec: 1))
      # => "TO_TIMESTAMP('2017-01-04 19:41:53:000001','YYYY-MM-DD HH24:MI:SS:FF6')"
      #
      # This patch should be disabled in config/environment.rb and removed after
      # upgrading activerecord-oracle_enhanced-adapter to 1.7, which should
      # coincide with an upgrade to Rails 5.

      def quote(value, column = nil) #:nodoc:
        if value && column
          case column.type
          when :text, :binary
            %Q{empty_#{ type_to_sql(column.type.to_sym).downcase rescue 'blob' }()}
          # NLS_DATE_FORMAT independent TIMESTAMP support
          when :timestamp
            quote_timestamp_with_to_timestamp(value)
          # NLS_DATE_FORMAT independent DATE support
          when :date, :time, :datetime
            quote_date_with_to_date(value)
          when :raw
            quote_raw(value)
          when :string
            # NCHAR and NVARCHAR2 literals should be quoted with N'...'.
            # Read directly instance variable as otherwise migrations with table column default values are failing
            # as migrations pass ColumnDefinition object to this method.
            # Check if instance variable is defined to avoid warnings about accessing undefined instance variable.
            column.instance_variable_defined?("@nchar") && column.instance_variable_get("@nchar") ? "N" << super : super
          else
            super
          end
        elsif value.acts_like?(:date)
          quote_date_with_to_date(value)
        elsif value.acts_like?(:time)
          quote_timestamp_with_to_timestamp(value)
        else
          super
        end
      end

    end

  end

end
# rubocop:enable Style/BarePercentLiterals, Style/RescueModifier, Layout/SpaceInsideStringInterpolation, Style/UnneededPercentQ
