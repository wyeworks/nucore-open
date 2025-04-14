module UmassCorum

  module JournalExtension

    MAX_ALS = 999

    def self.included(base)
      base.before_validation :set_als_number_and_fiscal_year, on: :create
      base.validates :fiscal_year, presence: true, if: :als_number
      base.validates :als_number, uniqueness: { scope: :fiscal_year,
                                                message: "can only be used once per fiscal year" }, allow_nil: true, numericality: { less_than_or_equal_to: MAX_ALS, greater_than: 0 }
    end

    def set_als_number_and_fiscal_year
      self.fiscal_year = SettingsHelper.fiscal_year_beginning(journal_date)
      self.als_number = most_recent_als_number + 1
    end

    private

    def most_recent_als_number
      Journal.where(fiscal_year: fiscal_year).maximum(:als_number).presence || 0
    end

  end

end
