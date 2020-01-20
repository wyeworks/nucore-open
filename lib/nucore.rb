# frozen_string_literal: true

module NUCore

  class PermissionDenied < RuntimeError
  end

  class Error < StandardError
  end

  class MixedFacilityCart < NUCore::Error
  end

  class NotPermittedWhileActingAs < NUCore::Error
  end

  class PurchaseException < NUCore::Error; end

  module Database

    def self.oracle?
      @@is_oracle ||= ActiveRecord::Base.connection.adapter_name == "OracleEnhanced"
    end

    def self.mysql?
      @@is_mysql ||= ActiveRecord::Base.connection.adapter_name == "Mysql2"
    end

    def self.boolean(value)
      # Oracle doesn't always properly handle boolean values correctly
      if oracle?
        value ? 1 : 0
      else
        value ? true : false
      end
    end

    def self.sample(scope, count = 1)
      if NUCore::Database.oracle?
        scope.order(Arel.sql("DBMS_RANDOM.VALUE")).limit(count)
      else
        scope.order(Arel.sql("RAND()")).limit(count)
      end
    end

    def self.random(scope)
      sample(scope).first
    end

    module WhereIdsIn

      extend ActiveSupport::Concern

      module ClassMethods

        # Oracle has a limit of 1000 items in a WHERE IN clause. Use this in
        # place of `where(id: ids)` when there might be more than 1000 ids.
        # Example: facility.order_details.complete.where_ids_in(ids)
        def where_ids_in(ids, batch_size: 999)
          if NUCore::Database.oracle?
            return none if ids.blank?

            clauses = ids.each_slice(batch_size).map do |id_slice|
              "#{table_name.upcase}.ID IN (#{id_slice.join(', ')})"
            end
            where(clauses.join(" OR "))
          else
            where(id: ids)
          end
        end

        # Handle `finds` of more than 1000 because Oracle does not allow 1000+
        # items in a WHERE IN. Raises an error if all the items are not
        # found, just like `find`
        def find_ids(ids)
          if NUCore::Database.oracle?
            results = where_ids_in(ids)
            # This is the same method `find` uses to get an exception message like "(found 1 results, but was looking for 2)"
            all.raise_record_not_found_exception!(ids, results.size, ids.size) unless results.length == ids.length
            results
          else
            find(ids)
          end
        end

      end

    end

    module DateHelper

      def self.included(base)
        base.extend ClassMethods
      end

      # Two digit years gte this value will be treated as 19XX
      Y2K_CUTOFF = 86

      module ClassMethods

        def parse_2_digit_year_date(date_string)
          day, month, year = date_string.match(/\A(\d{1,2})\-?([A-Z]{3})\-?(\d\d)\z/).captures
          year = year.to_i >= Y2K_CUTOFF ? "19#{year}" : "20#{year}"
          Time.zone.parse("#{day} #{month} #{year}")
        end

      end

    end

    module SortHelper

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        # MySQL by default will sort with nulls coming before anything with a value.
        # Oracle by defaults puts the nulls at the end in ASC mode
        def order_by_asc_nulls_first(field)
          order_by = NUCore::Database.oracle? ? "#{field} ASC NULLS FIRST" : field.to_s
           order(Arel.sql(sanitize_sql_for_order(order_by)))
        end

        def order_by_desc_nulls_first(field)
          order_by = NUCore::Database.oracle? ? "#{field} DESC NULLS FIRST" : "#{field} DESC"
          order(Arel.sql(sanitize_sql_for_order(order_by)))
        end

      end

    end

    module CaseSensitivityHelper

      def insensitive_where(relation, column, value)
        relation.where("UPPER(#{column}) = UPPER(?)", value)
      end

    end

  end

end
