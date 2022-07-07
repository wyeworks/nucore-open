# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "projects/version"

Gem::Specification.new do |s|
  s.name    = "projects"
  s.version = Projects::VERSION
  s.authors  = ["Table XI"]
  s.email    = "devs@txidigital.com"
  s.homepage = "https://github.com/tablexi/nucore-open"
  s.summary = "Optional projects feature"
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*", "spec/factories/**/*"]
end
