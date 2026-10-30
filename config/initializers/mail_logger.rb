# frozen_string_literal: true

class MailLogger < ActiveSupport::LogSubscriber
  def deliver(event)
    info do
      pairs = ["sent_at: #{event.time}"]
      event.payload.slice(:mailer, :subject, :to, :from).each_pair { |k, v| pairs << "#{k}: #{v}" }
      "\n>>>MailLogger>>> " + pairs.join(", ")
    end
  end
end

MailLogger.attach_to :action_mailer
