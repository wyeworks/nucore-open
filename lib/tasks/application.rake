# frozen_string_literal: true

namespace :daemon do
  desc "start daemon found in lib/daemons"
  task :start, [:daemon_name] do |_t, args|
    manage_daemon(args.daemon_name, "start")
  end

  desc "stop daemon found in lib/daemons"
  task :stop, [:daemon_name] do |_t, args|
    manage_daemon(args.daemon_name, "stop")
  end

  desc "start daemon found in lib/daemons in debug mode"
  task :debug, [:daemon_name] do |_t, args|
    manage_daemon(args.daemon_name, "run")
  end

  def manage_daemon(daemon_name, state)
    daemon = File.expand_path(File.join("..", "daemons", "#{daemon_name}.rb"), File.dirname(__FILE__))
    system "ruby #{daemon} #{state}"
  end
end
