# frozen_string_literal: true

RSpec.configure do |config|
  config.before :each, :use_test_account do
    allow(AccountValidator::ValidatorFactory).to(
      receive(:instance) do |account_number, *args|
        if account_number.start_with?(TestAccount::NUMBER_PREFIX)
          TestAccountValidator.new(account_number, *args)
        else
          AccountValidator::ValidatorFactory.validator_class.new(account_number, *args)
        end
      end
    )
    Account.config.account_types << TestAccount.name
  end

  config.after :each, :use_test_account do
    Account.config.account_types.delete TestAccount.name
  end

  config.before :each, :test_account_internal do
    Account.config.journal_account_types << TestAccount.name
  end

  config.after :each, :test_account_internal do
    Account.config.journal_account_types.delete TestAccount.name
  end

  config.around :each, :use_test_account do |example|
    test_view_path = Rails.root.join("spec/support/views")
    view_paths_before = ApplicationController.view_paths

    ApplicationController.append_view_path test_view_path

    example.run

    ApplicationController.view_paths = view_paths_before
  end
end
