# frozen_string_literal: true

FactoryBot.define do

  factory :log_event do
    loggable {}
    event_type { "MyString" }
    user { nil }
  end

end
