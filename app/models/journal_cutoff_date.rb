# frozen_string_literal: true

class JournalCutoffDate < ApplicationRecord

  include DateTimeInput::Model
  date_time_inputable :cutoff_date

  validates :cutoff_date, presence: true
  validate :unique_month_for_cutoff_date, if: :cutoff_date?

  scope :recent_and_upcoming, -> { where("cutoff_date > ?", 1.month.ago.beginning_of_month).order(:cutoff_date) }
  scope :past, -> { where("cutoff_date < ?", Time.current).order(:cutoff_date) }

  def self.first_valid_date
    past.last.try(:cutoff_date).try(:beginning_of_month)
  end

  def last_valid_date
    cutoff_date.prev_month.end_of_month
  end

  def past?
    cutoff_date < Time.current
  end

  private

  def unique_month_for_cutoff_date
    query = self.class
                .month_equal(cutoff_date.month)
                .year_equal(cutoff_date.year)

    # Do not conflict with itself
    query = query.where("id != ?", id) if persisted?

    if query.exists?
      errors.add(:cutoff_date, :month_taken, month: I18n.l(cutoff_date, format: "%B"))
    end
  end

  def self.month_equal(month)
    time_section_equal("MONTH", month)
  end

  def self.year_equal(year)
    time_section_equal("YEAR", year)
  end

  def self.time_section_equal(section, time)
    if Nucore::Database.oracle?
      # EXTRACT(MONTH from cutoff_date)
      where("EXTRACT(#{section} FROM cutoff_date) = ?", time)
    else
      # MONTH(cutoff_date)
      where("#{section}(cutoff_date) = ?", time)
    end
  end

end
