# frozen_string_literal: true

begin
  require File.join(File.dirname(__FILE__), "lib", "haml") # From here
rescue LoadError
  require "haml" # From gem
end
