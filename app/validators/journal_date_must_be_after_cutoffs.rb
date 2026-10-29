# frozen_string_literal: true

class JournalDateMustBeAfterCutoffs < ActiveModel::Validator
  def validate(record)
    Validator.new(record).validate
  end

  # This class is so we can encapsulate `record` in an instance variable so it's
  # not necessary to pass it around as an argument everywhere.
  class Validator
    include DateHelper

    delegate :journal_date, :errors, to: :record
    attr_reader :record

    def initialize(record)
      @record = record
    end

    def validate
      return unless journal_date.present?
      add_error if first_valid_date && first_valid_date > journal_date.beginning_of_day
    end

    private

    def add_error
      errors.add(:base, :must_be_after_cutoffs, cutoff: formatted_cutoff, month: attempted_month)
    end

    def attempted_month
      I18n.l(journal_date, format: "%B")
    end

    def formatted_cutoff
      format_usa_date(first_valid_date)
    end

    def first_valid_date
      @first_valid_date ||= JournalCutoffDate.first_valid_date
    end
  end
end
