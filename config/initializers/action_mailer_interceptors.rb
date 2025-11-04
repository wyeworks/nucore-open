# frozen_string_literal: true

# StagingMailInterceptor is autoloaded from app/lib/staging_mail_interceptor.rb

ActionMailer::Base.register_interceptor(StagingMailInterceptor) if Settings.email.fake.enabled
