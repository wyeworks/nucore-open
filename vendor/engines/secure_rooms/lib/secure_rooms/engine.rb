# frozen_string_literal: true

module SecureRooms

  class Engine < ::Rails::Engine

    isolate_namespace SecureRooms

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "SecureRooms::AbilityExtension"

      NavTab::LinkCollection.send :include, SecureRooms::LinkCollectionExtension
      OrderDetail.send :include, SecureRooms::OrderDetailExtension
      Facility.send :include, SecureRooms::FacilityExtension
      User.send :include, SecureRooms::UserExtension
      ::OrderDetails::ParamUpdater.send :include, SecureRooms::OrderDetails::ParamUpdaterExtension

      TransactionSearch.register_optimizer(SecureRooms::NPlusOneOccupancyOptimizer)

      ArrayUtil.insert_before(Product.types, SecureRoom, Bundle)
      ArrayUtil.insert_after(
        MessageSummarizer.summary_classes,
        SecureRooms::ProblemOccupancyMessageSummary,
        MessageSummarizer::ProblemReservationOrderDetailsSummary,
      )

      RecurringTaskConfig.recurring_tasks << [SecureRooms::AutoOrphanOccupancy, :perform, 5]

      UserFinder.searchable_columns << "card_number"
      UserFinder.searchable_columns << "i_class_number"

      ViewHook.add_hook "users.show",
                        "additional_user_fields",
                        "secure_rooms/shared/card_number_form_field"

      ViewHook.add_hook "admin.shared.tabnav_product",
                        "additional_tabs",
                        "secure_rooms/shared/tabnav_secure_room"

      ViewHook.add_hook "admin.shared.tabnav_users",
                        "after",
                        "secure_rooms/shared/tabnav_users"

      ViewHook.add_hook "search.results_table", "extra_headers", "search/extra_headers"
      ViewHook.add_hook "search.results_table", "extra_columns", "search/extra_columns"
    end

    initializer "secure_rooms.action_controller" do
      ActiveSupport.on_load :action_controller do
        helper SecureRooms::SecureRoomsHelper
      end
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
