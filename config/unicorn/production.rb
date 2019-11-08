# frozen_string_literal: true

worker_processes 4
preload_app true

# The full path without `..`s will expand to
# `/home/nucore/corum-ENV.umass.edu/releases/2019XXXXXXXX/config/unicorn`, so the
# result should be `/home/nucore/corum-ENV.umass.edu`
app_path = File.expand_path('../../../..', __dir__)
working_directory "#{app_path}/current"
pid               "#{app_path}/shared/tmp/pids/unicorn.pid"

listen 3000

stderr_path "log/unicorn.stderr.log"
stdout_path "log/unicorn.stdout.log"

# zero downtime
before_fork do |server, _|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)

  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |_, _|
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
end

before_exec do |_|
  ENV["BUNDLE_GEMFILE"] = "#{app_path}/current/Gemfile"
end
