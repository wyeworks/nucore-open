# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "fine_uploader/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "fine_uploader"
  s.version     = FineUploader::VERSION
  s.authors     = ["Jason Hanggi"]
  s.email       = ["devs@txidigital.com"]
  s.homepage    = "http://fineuploader.com/"
  s.summary     = "FineUploader for Rails Asset Pipeline"
  s.description = "FineUploader for Rails Asset Pipeline."
  s.license     = "MIT"

  s.files = Dir["{lib,vendor}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.2.6"
end
