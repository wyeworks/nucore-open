# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sanger_sequencing/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sanger_sequencing"
  s.version     = SangerSequencing::VERSION
  s.authors     = ["Table XI"]
  s.email       = "devs@txidigital.com"
  s.homepage    = "https://github.com/tablexi/nucore-open"
  s.summary     = "Sanger Sequencing module for NUcore"
  s.description = "Sanger Sequencing module for NUcore"

  s.files = Dir["{app,config,db,lib,spec}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 4.0"
  # s.add_dependency "jquery-rails"
end
