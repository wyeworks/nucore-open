# frozen_string_literal: true

module SangerSequencing

  class Engine < ::Rails::Engine

    config.to_prepare do
      NavTab::LinkCollection.send :include, SangerSequencing::LinkCollectionExtension

      ViewHook.add_hook "orders.receipt", "after_note", "sanger_sequencing/orders/samples_on_receipt"
      ViewHook.add_hook "purchase_notifier.order_receipt", "after_note", "sanger_sequencing/orders/samples_on_receipt"
    end

    config.generators do |g|
      g.test_framework :rspec
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
