# frozen_string_literal: true

module Fullcalendar

  class Engine < Rails::Engine

    require "momentjs-rails"

    initializer "fullcalendar.assets.precompile" do |app|
      app.config.assets.paths << root.join("vendor", "assets", "stylesheets")
      app.config.assets.precompile += %w[ fullcalendar.js fullcalendar.css ]
    end

  end

end
