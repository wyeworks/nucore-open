# frozen_string_literal: true

module FineUploader
  class Engine < Rails::Engine
    initializer "fine_uploader.assets.precompile" do |app|
      app.config.assets.precompile += %w[fine-uploader/*.js fine-uploader/*.css]
    end
  end
end
