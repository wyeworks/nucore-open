# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "fullcalendar/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "fullcalendar"
  s.version     = Fullcalendar::VERSION
  s.authors     = ["Jason Hanggi"]
  s.email       = ["devs@txidigital.com"]
  s.homepage    = "https://fullcalendar.io/"
  s.summary     = "FullCalendar for Rails Asset Pipeline"
  s.description = "FullCalendar for Rails Asset Pipeline."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "momentjs-rails"
end
