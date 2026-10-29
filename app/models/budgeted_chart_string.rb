# frozen_string_literal: true

class BudgetedChartString < ApplicationRecord
  include Nucore::Database::DateHelper

  validates :fund, :dept, :starts_at, :expires_at, presence: true
  validates   :fund, length: { is: 3 }
  validates   :dept, length: { is: 7 }
  validates   :project, length: { is: 8, allow_blank: true }
  validates   :activity, length: { is: 2, allow_blank: true }
  validates   :account, length: { is: 5, allow_blank: true }

  def self.import(filename)
    file = begin
      File.open(filename, "r")
    rescue
      nil
    end
    if file.blank?
      puts "error: Invalid file #{filename}"
      return
    end

    count
    imported  = 0
    skipped   = 0
    invalid   = 0

    transaction do
      # delete all records
      delete_all

      # import records
      begin
        # add testing/place holder records
        BudgetedChartString.create(fund: "123", dept: "1234567", project: "12345678", account: "75340",
                                   starts_at: 1.week.ago, expires_at: 1.year.from_now)
        BudgetedChartString.create(fund: "123", dept: "1234567", project: "12345678", account: "50617",
                                   starts_at: 1.week.ago, expires_at: 1.year.from_now)
        BudgetedChartString.create(fund: "111", dept: "2222222", project: "33333333", account: "75340",
                                   starts_at: 1.week.ago, expires_at: 1.year.from_now)
        BudgetedChartString.create(fund: "111", dept: "2222222", project: "33333333", account: "50617",
                                   starts_at: 1.week.ago, expires_at: 1.year.from_now)
        while line = file.readline.strip
          # parse, import line
          if /^\d{4,4}\|/.match?(line)
            # chart string with fiscal year
            tokens = line.split("|").map { |s| s.delete("-") }
            # build start_at, expires_at from fiscal year
            fiscal_year = tokens[0]
            starts_at   = SettingsHelper.fiscal_year(fiscal_year.to_i) # Time.zone.parse("#{fiscal_year}0901")
            expires_at  = starts_at + 1.year - 1.second
            # parse fields
            fund = tokens[1]
            dept = tokens[2]
            project = tokens[3]
            activity = tokens[4]
            account = tokens[5]
          elsif /\d{2,2}-[A-Z]{3,3}-\d{2,2}\|\d{2,2}-[A-Z]{3,3}-\d{2,2}$/.match?(line)
            # chart string with start and expire dates
            tokens = line.split("|").map { |s| s.delete("-") }
            # parse fields
            fund = tokens[1]
            dept = tokens[2]
            project = tokens[3]
            activity = tokens[4]
            account = tokens[5]
            starts_at = parse_2_digit_year_date(tokens[6])
            expires_at = parse_2_digit_year_date(tokens[7]).end_of_day
          else
            # invalid line
            puts "error: skipping - #{line}"
            skipped += 1
          end
          bcs = BudgetedChartString.create(fund:, dept:, project:, activity:, account:,
                                           starts_at:, expires_at:)
          if bcs.valid?
            imported += 1
          else
            puts "error: invalid account - #{line}"
            invalid += 1
          end
        end
      rescue EOFError
        file.close
        logger.info "notice: imported #{imported} records, skipped #{skipped} records, found #{invalid} invalid records"
      end
    end
  end
end
