# frozen_string_literal: true

ActionMailer::Base.register_interceptor(StagingMailInterceptor) if Settings.email.fake.enabled
