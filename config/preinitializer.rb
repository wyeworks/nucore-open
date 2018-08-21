# frozen_string_literal: true

begin
  require File.expand_path("../../.bundle/environment", __FILE__)
rescue LoadError
  require "rubygems"
  require "bundler"
  Bundler.setup
end
