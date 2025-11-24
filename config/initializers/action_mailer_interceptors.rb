# frozen_string_literal: true

if Settings.email.fake.enabled
  require "staging_mail_interceptor"
  ActionMailer::Base.register_interceptor(StagingMailInterceptor)
end
