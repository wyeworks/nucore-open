# frozen_string_literal: true

Rails.application.config.action_view.sanitized_allowed_attributes = Rails::Html::Sanitizer.white_list_sanitizer.allowed_attributes +
  %w[style target]
Rails.application.config.action_view.sanitized_allowed_tags = Rails::Html::Sanitizer.white_list_sanitizer.allowed_tags +
  %w[table thead tbody th tr td]
