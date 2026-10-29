# frozen_string_literal: true

require "rubygems"
require "daemons"

#
# This class provides a base for running daemons
# alongside NUcore. It wraps the Daemons API
# so that you don't have to think about it.
# http://daemons.rubyforge.org/
class Daemons::Base
  include Daemons

  #
  # [_name_]
  #   What you want to call the daemon. Log and PID
  #   files will be named after +name+, as will the
  #   the actual process in `ps` output

  def initialize(name)
    @rails_root = File.expand_path(File.join("..", ".."), File.dirname(__FILE__))
    self.name = name
    self.daemon_opts = {
      dir_mode: :normal,
      dir: File.join(@rails_root, "tmp/pids"),
      backtrace: true,
      monitor: monitor?,
      log_output: true,
      log_dir: File.join(@rails_root, "log"),
    }
  end

  #
  # Same as that given to #initialize. Use this accessor
  # if you want to change the name before calling #start
  attr_accessor :name

  #
  # The set of options passed to +Daemons#run_proc+ by #start.
  # A default set is created when #initialize is called.
  # If you want to change the default use this accessor
  # before calling #start
  attr_accessor :daemon_opts

  #
  # Fires up the daemon. Wraps +Daemons#run_proc+.
  # [_work_]
  #   The work that the daemon should do. You do not
  #   have to wrap the work in an infinite loop because
  #   this method will do so for you.
  def start(&)
    run_proc(name, daemon_opts) do
      require File.join(@rails_root, "config", "environment")
      loop(&)
    end
  end

  private

  # See usage notes in doc/HOWTO_daemons.txt
  def monitor?
    !ARGV.include?("--no-monitor")
  end
end
