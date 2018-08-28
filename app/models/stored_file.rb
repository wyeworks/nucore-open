# frozen_string_literal: true

class StoredFile < ApplicationRecord

  include DownloadableFile

  belongs_to              :product
  belongs_to              :creator, class_name: "User", foreign_key: "created_by"
  belongs_to              :order_detail
  validates_presence_of   :name, :file_type, :created_by
  validates_presence_of   :product_id,      if: ->(o) { o.file_type == "info" || o.file_type == "template" }
  validates_presence_of   :order_detail_id, if: ->(o) { o.file_type == "template_result" || o.file_type == "sample_result" }
  validates_inclusion_of  :file_type, in: %w(info template template_result sample_result import_error import_upload)
  validates :name, uniqueness: { scope: :order_detail_id }, if: :order_detail_id?

  delegate :user, to: :order_detail
  delegate :sample_result?, :template_result?, to: :type_inquirer

  scope :import_error, -> { where(file_type: "import_error") }
  scope :import_upload, -> { where(file_type: "import_upload") }
  scope :info, -> { where(file_type: "info") }
  scope :sample_result, -> { where(file_type: "sample_result") }
  scope :template, -> { where(file_type: "template") }
  scope :template_result, -> { where(file_type: "template_result") }

  validates_attachment_presence :file

  def read
    Paperclip.io_adapters.for(file).read
  end

  # Map file extensions to mime types.
  # Thanks to bug in Flash 8 the content type is always set to application/octet-stream.
  # From: http://blog.airbladesoftware.com/2007/8/8/uploading-files-with-swfupload
  def swf_uploaded_data=(data)
    data.content_type = MIME::Types.type_for(data.original_filename).first.to_s
    self.file = data
  end

  private

  def type_inquirer
    ActiveSupport::StringInquirer.new(file_type)
  end

end
