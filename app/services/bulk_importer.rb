# frozen_string_literal: true

##
# Base bulk importer class
#
# When importing data from a CSV then subclasses should
# implement the method *load_row(data)*, where data is
# a Hash instance with snake cased keys.
#
#   class SomeCSVImporter < BulkImporter
#     def load_row(data)
#       record = create_record(data)
#
#       if record.persisted?
#         results << record.to_s
#       else
#         errors << record.to_s
#       end
#     end
#   end
#
# Else they should override *load!* and access
# data through *filecontent*.
#
#   class SomeImporter < BulkImporter
#     def load!
#       # do something with filecontent
#     end
#   end
#
# Attributes *results* and *errors* are array of strings
# to be displayed to users.
#
# Exceptions raised on *load_row* of type `NUCore::BulkImporterError` will
# be catched and rows will continue to load unless `runs_in_transaction` is true
# which causes the whole loading to run in a transaction and be rolled-back when
# any error is raised.
#
# Other exceptions will stop the execution.
#
class BulkImporter
  attr_reader :bulk_import, :results, :errors

  def self.required_headers
    new(nil).required_headers
  end

  def initialize(bulk_import)
    @bulk_import = bulk_import
    @results = []
    @errors = []
  end

  def load!
    bulk_import.status_in_progress!

    transaction do
      load_records!
    end

    if errors.empty?
      save_execution(:done)
    elsif run_in_transaction?
      save_failure(errors.last)
    else
      save_execution(:done_errors)
    end
  rescue => e
    unless e.is_a?(ActiveRecord::AdapterError)
      save_failure(e.message || e.to_s)
    end

    raise
  end

  ##
  # Run in a DB transaction and commit everything or nothing.
  # When enabled, it causes the load to fail if any error is raised.
  #
  def run_in_transaction?
    false
  end

  def required_headers
    []
  end

  private

  def load_records!
    csv.each_with_index do |row, index|
      validate_headers!(row) if index.zero?
      result = load_row(normalize_data(row))

      results << result.to_s
    rescue NUCore::BulkImporterError => e
      errors << format_row_error(index + 1, e.message || e.to_s)
    rescue ActiveRecord::RecordInvalid => e
      errors << format_row_error(index + 1, e.record.errors.full_messages.join(". "))
    ensure
      raise ActiveRecord::Rollback if errors.present? && run_in_transaction?
    end
  end

  def transaction(&)
    if run_in_transaction?
      BulkImport.transaction(&)
    elsif block_given?
      yield
    end
  end

  def load_row(data)
    raise NotImplementedError
  end

  def csv
    CSV.parse(
      filecontent.encode("UTF-8"),
      headers: true,
      strip: true,
    )
  end

  def filecontent
    bulk_import.read_attached_file
  end

  def validate_headers!(row)
    return if required_headers.blank?

    normalized_required = required_headers.map { |h| normalize_header(h) }
    normalized_row_keys = row.to_h.keys.map { |h| normalize_header(h) }
    return if (normalized_required - normalized_row_keys).empty?

    raise "Required columns are #{required_headers.join(', ')}"
  end

  def normalize_data(row)
    row.to_h.transform_keys do |key|
      normalize_header(key)
    end.with_indifferent_access
  end

  def normalize_header(key)
    key.to_s.parameterize.underscore
  end

  def save_execution(status)
    bulk_import.update(
      status:,
      load_errors: errors,
      results:,
    )
  end

  def save_failure(message)
    bulk_import.update(
      status: :failed,
      failure: message,
    )
  end

  def format_row_error(row_number, error_message)
    "##{row_number}: #{error_message}"
  end
end
