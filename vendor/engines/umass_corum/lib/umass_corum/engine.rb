# frozen_string_literal: true

module UmassCorum

  class Engine < ::Rails::Engine

    config.autoload_paths << File.join(File.dirname(__FILE__), "../../lib")

    isolate_namespace UmassCorum

    config.to_prepare do
      User.include UmassCorum::UserExtension
      UsersController.user_form_class = UmassCorum::UserForm
      GlobalSearchController.include UmassCorum::GlobalSearchControllerExtension
      EngineManager.allow_view_overrides!("umass_corum")
      Account.config.account_types.concat(["UmassCorum::VoucherSplitAccount", "UmassCorum::SubsidyAccount"])
      Account.config.statement_account_types << "UmassCorum::VoucherSplitAccount"
      Account.config.account_types.unshift("UmassCorum::SpeedTypeAccount")
      Account.config.account_types.uniq!
      Account.config.journal_account_types << "UmassCorum::SubsidyAccount"
      Account.config.journal_account_types.unshift("UmassCorum::SpeedTypeAccount")
      Account.config.journal_account_types.uniq!
      Account.config.creation_disabled_types << "NufsAccount"
      OrderStatus.ordered_root_statuses << "MIVP Pending"
      FacilityFacilityAccountsController.form_class = UmassCorum::FacilityAccountForm
      Journal.include UmassCorum::JournalExtension
      NotificationSender.prepend UmassCorum::NotificationSenderExtension
      ::AbilityExtensionManager.extensions << "UmassCorum::AbilityExtension"
      ViewHook.add_hook("admin.shared.sidenav_global", "after", "umass_corum/shared/admin_reports_tab")
      ViewHook.add_hook("devise.sessions.new", "login_screen_announcement", "umass_corum/sessions/request_login")
      ViewHook.add_hook("devise.sessions.new", "login_form", "umass_corum/sessions/login_form")
      ViewHook.add_hook("users.edit", "custom_fields", "umass_corum/users/custom_fields")
      ViewHook.add_hook("users.show", "custom_fields", "umass_corum/users/custom_fields")
      ViewHook.add_hook("users.new_external", "custom_fields", "umass_corum/users/new_external_custom_fields")
      ViewHook.add_hook("admin.shared.sidenav_billing", "custom_reconcilable_account_types", "facility_accounts/mivp_sidenav")
      ViewHook.add_hook("facility_accounts.show", "additional_account_fields", "facility_accounts/custom_fields")
      ViewHook.add_hook("facility_accounts.show", "top_of_readonly_form", "facility_accounts/account_label")
      ViewHook.add_hook("accounts.show", "after_end_of_form", "accounts/project_dates")
      ::Reports::ExportRaw.transformers << "UmassCorum::AdminReports::ExportRawTransformer"
      SpeedTypeAccountBuilder.common_permitted_account_params << :api_speed_type_attributes
      VoucherSplitAccountBuilder.common_permitted_account_params << :account_number
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
