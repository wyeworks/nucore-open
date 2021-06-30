module UmassCorum

  module JournalExtension

    def self.included(base)
      base.before_create :generate_als_number, if: :als_generator_feature_on?
      base.validates :als_number, uniqueness: true
    end

    def als_generator_feature_on?
      SettingsHelper.feature_on?(:als_number_generator)
    end

    def generate_als_number
      self.als_number = ::UmassCorum::Journals::AlsNumberGenerator.next_als
    rescue ::UmassCorum::Journals::AlsNumberGenerator::AlsNumberError => e
      raise ActiveRecord::RecordInvalid.new(self)
    end

  end

end
