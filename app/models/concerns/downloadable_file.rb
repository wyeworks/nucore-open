# frozen_string_literal: true

# If Paperclip is used, then a migration is required for the model that includes this module
module DownloadableFile

  extend ActiveSupport::Concern

  if SettingsHelper.feature_on?(:active_storage)
    include ActiveStorageFile
  else
    include PaperclipFile
  end

  def file_present?
    file.present?
  end

end
