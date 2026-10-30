# frozen_string_literal: true

Rails.application.config.to_prepare do
  if Settings.ignore_passwords
    raise SecurityError.new("Username only authentication should only be used in development. Please check your settings.") unless Rails.env.development?

    require "devise/models/username_only_authenticatable"
    User.send(:devise, :username_only_authenticatable)

  end
end
