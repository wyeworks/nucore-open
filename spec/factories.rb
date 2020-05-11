# frozen_string_literal: true

require File.expand_path("factories_env", File.dirname(__FILE__))

FactoryBot.define do
  # Global trait
  trait :without_validation do
    to_create { |instance| instance.save(validate: false) }
  end
end
