# frozen_string_literal: true

# Add your fork-specific cron jobs here
# This file is automatically included by schedule.rb

# every 20.minutes do
#   rake "something"
# end

set :output, "log/#{@environment}.log"

every :day, at: "8:45am", roles: [:db] do
  rake "umass_corum:synchronize_speedtype_accounts"
end
