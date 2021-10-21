# frozen_string_literal: true

ENV["RAILS_ENV"] = @environment
require File.expand_path(File.dirname(__FILE__) + "/environment")

# IMPORTANT!!! You should never edit this file in your custom fork.
# If you want to add custom jobs to your instance, add them to schedule_custom.rb

# Override the default :rake option excluding the `--silent` option so output is
# still sent via email to sysadmins
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

every 5.minutes, roles: [:db] do
  command "curl --silent -X POST #{Rails.application.routes.url_helpers.admin_services_process_five_minute_tasks_url} --insecure"
end

every 1.minute, roles: [:db] do
  command "curl --silent -X POST #{Rails.application.routes.url_helpers.admin_services_process_one_minute_tasks_url} --insecure"
end

every :day, at: "4:17am", roles: [:db] do
  rake "order_details:remove_merge_orders"
end

every :day, at: "12:30am", roles: [:db] do
  rake "reservations:notify_offline"
end

require "active_support/core_ext/numeric/time"
instance_eval(File.read(File.expand_path("../schedule_custom.rb", __FILE__)), "schedule_custom.rb")

# Learn more: http://github.com/javan/whenever
