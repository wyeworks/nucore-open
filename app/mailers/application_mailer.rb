# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base

  default from: Settings.email.from

  add_template_helper TranslationHelper

  def mail(arguments)
    super
  end

end
