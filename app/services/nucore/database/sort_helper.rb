# frozen_string_literal: true

module Nucore

  module Database

    module SortHelper

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        # MySQL by default will sort with nulls coming before anything with a value.
        # Oracle and PostgreSQL by default put the nulls at the end in ASC mode
        def order_by_asc_nulls_first(field)
          order_by = Nucore::Database.oracle? || Nucore::Database.postgresql? ? "#{field} ASC NULLS FIRST" : field.to_s
          order(Arel.sql(sanitize_sql_for_order(order_by)))
        end

        def order_by_desc_nulls_first(field)
          order_by = Nucore::Database.oracle? || Nucore::Database.postgresql? ? "#{field} DESC NULLS FIRST" : "#{field} DESC"
          order(Arel.sql(sanitize_sql_for_order(order_by)))
        end

        def order_by_asc_nulls_last(field)
          order_by = if Nucore::Database.oracle?
                       field.to_s
                     elsif Nucore::Database.postgresql?
                       "#{field} ASC NULLS LAST"
                     else
                       "#{field} IS NULL, #{field} ASC"
                     end
          order(Arel.sql(sanitize_sql_for_order(order_by)))
        end

      end

    end

  end

end
