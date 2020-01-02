# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "nu_research_safety/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "nu_research_safety"
  s.version     = NuResearchSafety::VERSION
  s.authors     = ["Table XI"]
  s.email       = ["devs@tablexi.com"]
  s.homepage    = "https://nucore.northwestern.edu"
  s.summary     = "Certifications for NU Research Safety"
  s.description = "Certifications for NU Research Safety"

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
end
