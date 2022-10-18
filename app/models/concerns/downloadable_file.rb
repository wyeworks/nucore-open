# frozen_string_literal: true

module DownloadableFile

  extend ActiveSupport::Concern

  if SettingsHelper.feature_on?(:active_storage)
    include ActiveStorageFile
  else
    include PaperclipFile
  end

end
