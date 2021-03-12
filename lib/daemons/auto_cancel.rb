# frozen_string_literal: true

require File.expand_path("base", File.dirname(__FILE__))

Daemons::Base.new("auto_cancel").start do
  # Only run on 1 instance.
  if Rails.application.secrets.run_auto_cancel
    canceler = AutoCanceler.new
    canceler.cancel_reservations
  end

  sleep 1.minute.to_i
end
