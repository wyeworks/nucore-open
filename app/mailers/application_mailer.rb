# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base

  default from: Settings.email.from

  helper TranslationHelper

  def mail(arguments)
    super
  end

end
