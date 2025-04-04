# frozen_string_literal: true

guard :rspec, cmd: "bundle exec rspec", spec_paths: ["spec", "vendor/engines/*/spec"] do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^vendor/engines/\w+/spec/.+_spec\.rb$})
  watch(%r{^(vendor/engines/\w+)/app/(.+)\.rb$}) { |m| "#{m[1]}/spec/#{m[2]}_spec.rb" }
  watch(%r{^(vendor/engines/\w+)/(lib/.+)\.rb$}) { |m| "#{m[1]}/spec/#{m[2]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/support/(.+)\.rb$}) { |m| "spec/app_support/#{m[1]}_spec.rb" }
  watch("spec/spec_helper.rb") { "spec" }

  # Rails example
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch("config/routes.rb")                           { "spec/routing" }
  watch("app/controllers/application_controller.rb")  { "spec/controllers" }
  watch("spec/rails_helper.rb")                       { "spec" }
end

guard :teaspoon do
  # Implementation files
  watch(%r{^app/assets/javascripts/(.+)(\.js)?\.js$}) { |m| "#{m[1]}_spec#{m[2]}.js" }

  # Specs / Helpers
  watch(%r{^spec/javascripts/.+})
end
