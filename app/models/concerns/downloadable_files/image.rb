module DownloadableFiles

  module Image

    extend ActiveSupport::Concern

    if SettingsHelper.active_storage_enabled?
      include ActiveStorageFile
    else
      include PaperclipFile
    end

    included do
      attr_reader :remove_file

      before_validation { delete_file if remove_file }

      if SettingsHelper.active_storage_enabled?
        validates :file, content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]
      else
        validates_attachment :file, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }
      end
    end

    def file_present?
      file.present?
    end

    def remove_file=(value)
      @remove_file = !value.to_i.zero?
    end

    def padded_image(width: 400, height: 200, background_color: "rgb(231, 231, 231)")
      if SettingsHelper.active_storage_enabled?
        download_url.variant(resize_and_pad: [width, height, { background: background_color }])
      else
        download_url
      end
    end

  end

end
