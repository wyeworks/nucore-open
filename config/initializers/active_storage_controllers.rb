# frozen_string_literal: true

Rails.application.config.after_initialize do
  ActiveStorage::DirectUploadsController.include RequiresAuthentication
end
