# frozen_string_literal: true

module Nucore

  module Database

    module SortHelper

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        # MySQL by default will sort with nulls coming before anything with a value.
        # Oracle by defaults puts the nulls at the end in ASC mode
        def order_by_asc_nulls_first(field)
          order_by = Nucore::Database.oracle? ? "#{field} ASC NULLS FIRST" : field.to_s
          order(Arel.sql(sanitize_sql_for_order(order_by)))
        end

        def order_by_desc_nulls_first(field)
          order_by = Nucore::Database.oracle? ? "#{field} DESC NULLS FIRST" : "#{field} DESC"
          order(Arel.sql(sanitize_sql_for_order(order_by)))
        end

        def order_by_asc_nulls_last(field)
          order_by = Nucore::Database.oracle? ? field.to_s : "#{field} IS NULL, #{field} ASC"
          order(Arel.sql(sanitize_sql_for_order(order_by)))
        end

      end

    end

  end

end
