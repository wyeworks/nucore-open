# frozen_string_literal: true

module Nucore

  module Database

    module WhereIdsIn

      extend ActiveSupport::Concern

      module ClassMethods

        # Oracle has a limit of 1000 items in a WHERE IN clause. Use this in
        # place of `where(id: ids)` when there might be more than 1000 ids.
        # Example: facility.order_details.complete.where_ids_in(ids)
        def where_ids_in(ids, batch_size: 999)
          if Nucore::Database.oracle?
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
          if Nucore::Database.oracle?
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

  end

end
