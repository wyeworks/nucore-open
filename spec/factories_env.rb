# frozen_string_literal: true

#
# Here we setup the factory *environment*, not factories themselves (do that in factories.rb)
# Allows us to separate factory definitions from setup
#

include ActionDispatch::TestProcess

#
# Configure test env for specified validator
#

validator_factory = Settings.validator.test.factory
require Rails.root.join(validator_factory) if validator_factory.present?

validator_helper = Settings.validator.test.helper

if validator_helper.present?
  require Rails.root.join(validator_helper)
  include File.basename(validator_helper).camelize.constantize
end

#
# Allows overriding of factories by engines, etc.
def overridable_factory(factory_name, *, &)
  return if FactoryBot.factories.registered? factory_name
  FactoryBot.define do
    factory(factory_name, *) do
      instance_eval(&)
    end
  end
end
