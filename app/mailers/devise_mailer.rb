# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  # Allow us to use interpolations like `!app_name!` in the subject
  def subject_for(key)
    text("devise.mailer.#{key}.subject", default: super)
  end
end
