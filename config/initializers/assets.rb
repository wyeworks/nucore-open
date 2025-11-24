# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.precompile << %w[jquery.js jquery_ujs.js]

# Manually add chosen-rails assets paths since the gem's engine doesn't load for Rails 8
chosen_gem_path = Gem.loaded_specs['chosen-rails'].full_gem_path
Rails.application.config.assets.paths << File.join(chosen_gem_path, 'vendor', 'assets', 'javascripts')
Rails.application.config.assets.paths << File.join(chosen_gem_path, 'vendor', 'assets', 'stylesheets')
Rails.application.config.assets.paths << File.join(chosen_gem_path, 'vendor', 'assets', 'images')
