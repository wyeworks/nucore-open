# frozen_string_literal: true

set :application, "nucore"
set :eye_config, "config/eye.yml.erb"
set :eye_env, -> { { rails_env: fetch(:rails_env) } }
set :repo_url, "git@github.com:wyeworks/nucore-open.git"
set :rollbar_env, Proc.new { fetch :rails_env }
set :rollbar_role, Proc.new { :app }
set :rollbar_token, ENV["ROLLBAR_ACCESS_TOKEN"]

set :linked_files, fetch(:linked_files, []).concat(
  %w(config/database.yml config/secrets.yml),
)
set :linked_dirs, fetch(:linked_dirs, []).concat(
  %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/files),
)
