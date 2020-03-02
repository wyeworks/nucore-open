# frozen_string_literal: true

module Nucore

  module Database

    def self.oracle?
      return @is_oracle if defined?(@is_oracle)
      @is_oracle = ActiveRecord::Base.connection_config[:adapter] == "oracle_enhanced"
    end

    def self.mysql?
      return @is_mysql if defined?(@is_mysql)
      @is_mysql = ActiveRecord::Base.connection_config[:adapter] == "mysql2"
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
      if Nucore::Database.oracle?
        scope.order(Arel.sql("DBMS_RANDOM.VALUE")).limit(count)
      else
        scope.order(Arel.sql("RAND()")).limit(count)
      end
    end

    def self.random(scope)
      sample(scope).first
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

  end

end

# All of the Database and other sub-modules used to be in this file. Now, in order
# to deal with Rails autoloading, they need to be in `Nucore`. However, there are
# many legacy uses of the `NUCore` capitalization. Until we go through and clean them
# up, provide an alias.
# TODO: Replace usage of old capitalization
NUCore::Database = Nucore::Database
