# frozen_string_literal: true

module UmassCorum

  class Engine < ::Rails::Engine

    config.autoload_paths << File.join(File.dirname(__FILE__), "../../lib")

    isolate_namespace UmassCorum

    config.to_prepare do
      UsersController.user_form_class = UmassCorum::UserForm
      EngineManager.allow_view_overrides!("umass_corum")
      Account.config.account_types << "UmassCorum::VoucherSplitAccount"
      Account.config.statement_account_types << "UmassCorum::VoucherSplitAccount"
      Account.config.account_types.unshift(UmassCorum::SpeedTypeAccount.name)
      Account.config.account_types.uniq!
      Account.config.journal_account_types.unshift(UmassCorum::SpeedTypeAccount.name)
      Account.config.journal_account_types.uniq!
      Account.config.creation_disabled_types << "NufsAccount"
      FacilityFacilityAccountsController.form_class = UmassCorum::FacilityAccountForm
      Journal.send(:include, UmassCorum::JournalExtension)
      ResearchSafetyCertificationLookup.adapter_class = UmassCorum::OwlApiAdapter
      ViewHook.add_hook("devise.sessions.new", "login_screen_announcement", "umass_corum/sessions/request_login")
      ViewHook.add_hook("devise.sessions.new", "login_form", "umass_corum/sessions/login_form")
      ViewHook.add_hook("users.edit", "custom_fields", "umass_corum/users/custom_fields")
      ViewHook.add_hook("users.show", "custom_fields", "umass_corum/users/custom_fields")
      ViewHook.add_hook("users.new_external", "custom_fields", "umass_corum/users/new_external_custom_fields")
      ViewHook.add_hook("admin.shared.sidenav_billing", "custom_reconcilable_account_types", "facility_accounts/mivp_sidenav")
    end

    # Include migrations in main rails app
    # https://blog.pivotal.io/labs/labs/leave-your-migrations-in-your-rails-engines
    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

    # Include factories in main rails app
    initializer "model_core.factories", after: "factory_bot.set_factory_paths" do
      if defined?(FactoryBot)
        FactoryBot.definition_file_paths << File.expand_path("../../../spec/factories", __FILE__)
      end
    end

  end

end
