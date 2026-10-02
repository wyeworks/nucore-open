# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :ldap) do |example|
    User.define_method(:valid_ldap_authentication?) { |password| password == "netidpassword" }

    example.call

    User.remove_method(:valid_ldap_authentication?)
  end

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
end
