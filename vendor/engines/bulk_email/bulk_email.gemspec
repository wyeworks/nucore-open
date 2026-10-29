# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "bulk_email/version"

Gem::Specification.new do |s|
  s.name    = "bulk_email"
  s.version = BulkEmail::VERSION
  s.authors  = ["Table XI"]
  s.email    = "devs@txidigital.com"
  s.homepage = "https://github.com/tablexi/nucore-open"
  s.summary = "Bulk email feature"
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*", "spec/factories/**/*"]
  s.metadata["rubygems_mfa_required"] = "true"
end
