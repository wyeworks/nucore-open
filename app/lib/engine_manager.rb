# frozen_string_literal: true

# Keeper of this app's loaded engines
class EngineManager

  def self.loaded_engines
    Rails.application.railties
         .select { |r| r.class < Rails::Engine }
         .map(&:class).to_set
  end

  def self.loaded_nucore_engines
    loaded_engines.select { |e| e.root.to_s =~ %r(/vendor/engines/\w+\z) }
  end

  def self.engine_loaded?(engine_name)
    class_name = "#{engine_name.to_s.camelize}::Engine"
    loaded_engines.map(&:name).include?(class_name)
  end

  # Allow the engine's views to take precedence over the application's views.
  # Controllers and mailers keep separate view-path sets, so reorder both.
  def self.allow_view_overrides!(engine_name)
    [ActionController::Base, ActionMailer::Base].each do |base|
      paths = base.view_paths.to_a
      index = paths.find_index { |p| p.to_s.include?(engine_name) }
      next unless index

      paths.unshift paths.delete_at(index)
      base.view_paths = paths
    end
  end

end
