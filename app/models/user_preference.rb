# frozen_string_literal: true

class UserPreference < ApplicationRecord

  belongs_to :user
  validates :value, presence: true
  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }

  cattr_accessor(:options_list) { [] } # list of option class names

  def self.options_for(user)
    options_list.map { |class_name| class_name.new(user) }
                .select(&:visible_to_user?)
  end

  def self.create_missing_user_preferences(user)
    options_list.each do |option_class|
      option = option_class.new(user)
      preference = user.user_preferences.find_or_initialize_by(name: option.name)
      preference.value ||= option.default_value
      preference.save
    end
  end

  def option
    self.class.options_for(user).find { |opt| opt.name == name }
  end

end
