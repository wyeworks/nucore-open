# frozen_string_literal: true

# NOTE: only still in use by NU and UMass
# Add your fork-specific cron jobs here
# This file is automatically included by schedule.rb

# every 20.minutes do
#   rake "something"
# end

job_type :script, "cd :path && :task"

set :output, "log/#{@environment}.log"

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

