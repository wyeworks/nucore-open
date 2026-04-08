# frozen_string_literal: true

class BulkImport < ApplicationRecord
  cattr_accessor(:import_classes) { {} }

  belongs_to :created_by, class_name: "User"

  store :data, accessors: %i[results load_errors failure], coder: JSON

  validates(
    :import_type,
    presence: true,
    inclusion: {
      in: ->(bulk_imp) { bulk_imp.class.import_types },
    }
  )

  enum(
    :status,
    {
      new: "new",
      in_progress: "in_progress",
      done_errors: "done_errors",
      done: "done",
      failed: "failed",
    },
    prefix: true,
    default: "new",
  )

  include DownloadableFile

  scope :by_date, -> { order(created_at: :desc) }

  delegate :load!, to: :loader

  def loader
    loader_class.new(self)
  end

  def loader_class
    klass = self.class.import_classes.fetch(import_type)

    return klass if klass.is_a?(Class)

    klass.constantize
  end

  def self.import_types
    import_classes.keys
  end
end
