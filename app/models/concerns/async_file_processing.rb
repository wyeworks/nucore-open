# frozen_string_literal: true

# Include this module in one of your models to support asynchronous file processing
# via ActiveJob. It will only allow one instance of the model to be in process at
# a time.
#
# Requirements:
# * Model must have `status`, `processed_at`, and `error_message` columns, and
#   should have "processing" as the default for the `status` column
#   `add_column :status, default: "processing", null: false
# * Model must implement `process_file!` (see `FileProcessingJob`)
#   * `process_file!` should raise an error if anything goes wrong
#
# Example:
# class OrderImport < ApplicationRecord
#   include AsyncFileProcessing
#   def process_file!
#     do_something(file.path)
#   end
# end
#
# Note: Race conditions could happen, especially if you don't prevent double clicks
# on uploads, but they should be harmless outside of performance hits.
module AsyncFileProcessing

  extend ActiveSupport::Concern

  included do
    validates :status, inclusion: { in: %w(processing successful failed) }
    validate :only_one_in_queue_at_a_time, on: :create
  end

  delegate :processing?, :successful?, :failed?, to: :status_inquirer

  def enqueue
    return unless save
    FileProcessingJob.perform_later(self)
  end

  def another_in_queue?
    self.class.where(status: "processing").any?
  end

  def succeed!
    update!(status: "successful", processed_at: Time.current)
  end

  def fail!(message)
    update!(status: "failed", processed_at: Time.current, error_message: message)
  end

  private

  def status_inquirer
    ActiveSupport::StringInquirer.new(status)
  end

  def only_one_in_queue_at_a_time
    errors.add(:file, :already_in_queue) if another_in_queue?
  end

end
