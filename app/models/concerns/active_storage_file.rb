# frozen_string_literal: true

module ActiveStorageFile

  extend ActiveSupport::Concern

  included do
    # TODO: Limit attachment types for safe uploads
    has_one_attached :file

    def assign_attributes(new_attributes)
      if SettingsHelper.feature_on?(:active_storage)
        # Ensure the file name and file_type are set first when attaching a StringIO
        # see #file= method below
        assign_first = new_attributes.extract!(:name, :file_type)
        super(assign_first) unless assign_first.empty?
      end
      super(new_attributes)
    end
  end

  def download_url
    file
  end

  def read_attached_file
    return file.download if persisted?

    attachable = attachment_changes["file"]&.attachable
    if attachable.nil?
      nil
    elsif attachable.is_a?(Hash)
      read_io = attachable[:io].read
      attachable[:io].rewind
      read_io
    else
      # attachable is expected to be an instance of
      # ActiveStorage::Blob, ActionDispatch::Http::UploadedFile,
      # or Rack::Test::UploadedFile
      attachable.read
    end
  end

  def file_path
    # service is nil when no file is attached
    file.service&.path_for("file")
  end

  def update_filename(value)
    file.filename = value
  end

  def file=(attachable)
    attachable_is_a_file = (attachable.is_a?(StringIO) || attachable.is_a?(File))

    if attachable_is_a_file
      filename = try(:name) || "untitled"
      content_type = try(:file_type) || "text/csv"
      super({ io: attachable, filename: filename, content_type: content_type })
    else
      super
    end
  end

end
