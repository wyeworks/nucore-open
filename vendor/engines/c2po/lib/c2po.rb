# frozen_string_literal: true

module C2po

  C2PO_ACCOUNT_TYPES = %w(CreditCardAccount PurchaseOrderAccount).freeze

  C2PO_ACCOUNT_TYPES_APPENDER = proc do
    Account.config.account_types.concat C2po::C2PO_ACCOUNT_TYPES
    Account.config.facility_account_types.concat C2po::C2PO_ACCOUNT_TYPES
    Account.config.statement_account_types.concat C2po::C2PO_ACCOUNT_TYPES
    Account.config.affiliate_account_types.concat C2po::C2PO_ACCOUNT_TYPES
  end.freeze

  class Engine < Rails::Engine

    config.autoload_paths << File.join(File.dirname(__FILE__), "../lib")

    config.to_prepare do
      # Include extensions
      Facility.facility_account_validators << C2po::C2poAccountValidator

      # Permit engine-specific params
      FacilitiesController.permitted_facility_params.concat [:accepts_po, :accepts_cc]

      EngineManager.allow_view_overrides!("c2po")

      # Register view hooks
      ViewHook.add_hook "facilities.manage", "before_is_active", "c2po/facilities/manage"
      ViewHook.add_hook "facilities.facility_fields", "before_is_active", "c2po/facilities/facility_fields"
      ViewHook.add_hook "facility_accounts.show", "after_end_of_form", "c2po/facility_accounts/show/remittance_information"
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

    initializer :append_account_types, before: "set_routes_reloader_hook" do |app|
      C2PO_ACCOUNT_TYPES_APPENDER.call
      app.reloader.to_run(&C2PO_ACCOUNT_TYPES_APPENDER)
    end

    initializer "model_core.factories", after: "factory_girl.set_factory_paths" do
      if defined?(FactoryBot)
        FactoryBot.definition_file_paths << File.expand_path("../../spec/factories", __FILE__)
      end
    end

  end

end
