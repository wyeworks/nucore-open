# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:all, :enable_split_accounts) do
    SplitAccounts::Engine.enable! unless SettingsHelper.feature_on?("accounts.split_accounts")
  end

  config.after(:all, :enable_split_accounts) do
    SplitAccounts::Engine.disable! unless SettingsHelper.feature_on?("accounts.split_accounts")
  end
end
