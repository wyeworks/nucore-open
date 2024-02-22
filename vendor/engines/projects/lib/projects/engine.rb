# frozen_string_literal: true

module Projects

  class Engine < Rails::Engine

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "Projects::AbilityExtension"
      Facility.send :include, Projects::FacilityExtension
      GlobalSearchController.send :include, Projects::GlobalSearchControllerExtension
      NavTab::LinkCollection.send :include, Projects::LinkCollectionExtension
      ::OrderDetails::ParamUpdater.send :include, Projects::OrderDetails::ParamUpdaterExtension
      Order.send :include, Projects::OrderExtension
      OrderDetail.send :include, Projects::OrderDetailExtension
      OrderDetailBatchUpdater.send :include, Projects::OrderDetailBatchUpdaterExtension
      OrdersController.send :include, Projects::OrdersControllerExtension
      Reservation.send :include, Projects::ReservationExtension

      ViewHook.add_hook "reservations.account_field",
                        "after_account",
                        "projects/shared/select_project"

      ViewHook.add_hook "order_management.order_details.form",
                        "after_order_status",
                        "projects/shared/select_project"

      ViewHook.add_hook "order_management.order_details.print_details",
                        "after_account_print",
                        "projects/shared/project"

      ViewHook.add_hook "orders.form",
                        "acting_as",
                        "projects/shared/select_project"

      TransactionSearch.register(Projects::ProjectSearcher)

      ViewHook.add_hook "shared.transactions.search",
                        "end_of_first_column",
                        "projects/shared/transactions/search"

      ::Reports::ExportRaw.transformers << "Projects::ExportRawTransformer"

      ViewHook.add_hook "shared.order_detail_action_form",
                        "batch_update_above_product_column",
                        "projects/shared/select_facility_project"

      ::Reports::GeneralReportsController.reports[:project] = Projects::ReportsExtension.general_report
      ::Reports::InstrumentReportsController.reports[:project] = Projects::ReportsExtension.instrument_report
    end

    config.after_initialize do
      OrderRowImporter.send :prepend, Projects::OrderRowImporterExtension
      OrderRowImporter.order_import_headers.insert(-2, :project_name)
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

    initializer "model_core.factories", after: "factory_bot.set_factory_paths" do
      if defined?(FactoryBot)
        FactoryBot.definition_file_paths << File.expand_path("../../../spec/factories", __FILE__)
      end
    end

  end

end
