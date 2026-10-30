# frozen_string_literal: true

module Dataprobe
  class Engine < Rails::Engine
    config.autoload_paths << File.join(File.dirname(__FILE__), "../lib")
  end

  class Error < StandardError; end
end
