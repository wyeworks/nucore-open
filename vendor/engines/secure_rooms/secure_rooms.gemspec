# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "secure_rooms/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "secure_rooms"
  s.version     = SecureRooms::VERSION
  s.authors     = ["Table XI"]
  s.email       = ["devs@txidigital.com"]
  s.homepage    = "https://github.com/tablexi/nucore-open"
  s.summary     = "Optional Secure Room feature for NUcore"
  s.description = "Optional Secure Room feature for NUcore"

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]
end
