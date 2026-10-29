# frozen_string_literal: true

# Used by models/concerns/async_file_processing in AsyncFileProcessing
# This should only be used by a model including that class
class FileProcessingJob < ApplicationJob
  # process_file! is expected to raise an error if anything goes wrong
  def perform(object)
    object.process_file!
    object.succeed!
  rescue => e
    message = e.message + e.backtrace.join("\n")
    object.fail!(message)
  end
end
