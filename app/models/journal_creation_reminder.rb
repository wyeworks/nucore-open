# frozen_string_literal: true

# Messages to display when creating a new journal during the specified date range.
#
# Admin staff can still create journals for about a week after the end of the fiscal year.
# This is known as the 'year end closing window' - the date range between the
# end of the fiscal year and the journal cutoff date for the last month of the fiscal year.
#
# For example:
#   With FY22 starting 09/01/21, the closing window would
#   start Sep 1, 2021 and end on the August 2021 cutoff date:
#   Sep 1, 2021 - Sep 8, 2021.
class JournalCreationReminder < ApplicationRecord
  include DateHelper

  validates :message, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :starts_before_ends

  scope :current, -> { where("starts_at < ? and ? < ends_at", Time.current, Time.current) }

  def past?
    ends_at < Time.current
  end

  def starts_at=(date_string)
    super(parse_usa_date(date_string))
  end

  def ends_at=(date_string)
    super(parse_usa_date(date_string)&.end_of_day)
  end

  private

  def starts_before_ends
    if starts_at && ends_at
      errors.add(:starts_at, :start_after_end) if ends_at <= starts_at
    end
  end
end
