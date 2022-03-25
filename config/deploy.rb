# frozen_string_literal: true

set :application, "nucore"
set :eye_config, "config/eye.yml.erb"
set :eye_env, -> { { rails_env: fetch(:rails_env) } }
set :repo_url, "git@github.com:tablexi/nucore-umass.git"
set :rollbar_env, Proc.new { fetch :rails_env }
set :rollbar_role, Proc.new { :app }
set :rollbar_token, ENV["ROLLBAR_ACCESS_TOKEN"]

set :linked_files, fetch(:linked_files, []).concat(
  %w(config/database.yml config/secrets.yml config/saml-certificate.p12),
)
set :linked_dirs, fetch(:linked_dirs, []).concat(
  %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/files),
)

# This symlinks public/uploads to shared/uploads, which is an NFS mount
after "deploy:updated", :symlink_uploads do
  on roles :app do
    execute "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
  end
end

namespace :eye do
  task :set_recurring_tasks do
    on roles :db do |host|
      set :eye_env, -> { { rails_env: fetch(:rails_env), recurring: true } }
    end
  end
end

before "eye:load_config", "eye:set_recurring_tasks"
