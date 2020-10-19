# frozen_string_literal: true

module DownloadableFile

  extend ActiveSupport::Concern

  included do
    has_attached_file :file, PaperclipSettings.config.merge(
      validate_media_type: false,
      s3_url_options: { response_content_disposition: "attachment" } # this is ignored when using local storage
    )

    # TODO: Limit attachment types for safe uploads
    do_not_validate_attachment_file_type :file
  end

  def download_url
    file.expiring_url
  end

end
