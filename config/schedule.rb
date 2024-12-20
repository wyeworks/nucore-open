# frozen_string_literal: true
# NOTE: only used by UMass

ENV["RAILS_ENV"] = @environment
require File.expand_path(File.dirname(__FILE__) + "/environment")

require "active_support/core_ext/numeric/time"

# Override the default :rake option excluding the `--silent` option so output is
# still sent via email to sysadmins
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

job_type :script, "cd :path && :task"

set :output, "log/#{@environment}.log"

if ENV["RUN_CRON"]

  every :day, at: "4:17am", roles: [:db] do
    rake "order_details:remove_merge_orders"
  end

  every :day, at: "12:30am", roles: [:db] do
    rake "reservations:notify_offline"
  end

  every :day, at: "6:00am", roles: [:db] do
    rake "research_safety_adapters:scishield:synchronize_training"
  end

  every :day, at: "8:45am", roles: [:db] do
    rake "umass_corum:synchronize_speedtype_accounts"
  end

  # Render journals to be sent to UMass for processing
  every :day, at: "5:15pm", roles: [:db] do
    rake "umass_corum:render_and_move[$HOME/files/FTP-out/temp,$HOME/files/FTP-out/current]"
  end

  # Send the journals to the UMass financial system
  every :day, at: "5:20pm", roles: [:db] do
    script "vendor/engines/umass_corum/script/ftp-send.sh"
  end

else
  puts "Cron jobs are disabled. Set RUN_CRON=true to enable."
end

# Learn more: http://github.com/javan/whenever
