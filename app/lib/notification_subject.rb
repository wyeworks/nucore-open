# frozen_string_literal: true

#
# Models that produce messages for +Notification+s should include this module.
# In addition to the defined methods it makes the named route methods used in
# controllers and views available to including models
module NotificationSubject

  include Rails.application.routes.url_helpers

  #
  # Generates a message to be saved as a +Notification+ notice.
  # Implementation is left up to including class.
  def to_notice(_notification_class, *_args)
    raise "to be implemented by including class!"
  end

  private

  def default_url_options
    ActionMailer::Base.default_url_options
  end

end
