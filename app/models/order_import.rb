# frozen_string_literal: true

require "csv"

class OrderImport < ApplicationRecord

  belongs_to :facility
  belongs_to :upload_file, class_name: "StoredFile", dependent: :destroy, required: true
  belongs_to :error_file, class_name: "StoredFile", dependent: :destroy
  belongs_to :creator, class_name: "User", foreign_key: :created_by

  validates_presence_of :upload_file, :created_by
  attr_accessor :error_report

  delegate :download_url, to: :error_file, prefix: true, allow_nil: true

  def fetch_or_create_order!(row_importer)
    order_cache[row_importer.order_key] || create_order_from_imported_row!(row_importer)
  end

  #
  # Process each line of CSV file in #upload_file.
  #
  # if fail_on_error
  #   If an error is encountered create the exact
  #   same CSV with the error annotated in a new error column.
  #   Save error file to #error_file.
  # else
  #   Save all valid orders and keep track of any failures.
  #   At end of processing create a #error_file out of the failures.
  #   Include each failed line with the error annotated in a new error column.
  # end
  #
  # Be sure to honor #send_receipts
  #

  def process_upload!
    init_error_report

    if fail_on_error?
      handle_save_nothing_on_error
    else
      handle_save_clean_orders
    end

    store_error_report if result.failed?
    self.processed_at = Time.zone.now
    save!
  end

  def result
    @result ||= Result.new
  end

  def error_file_content
    error_file.try(:read)
  end

  def error_file_present?
    error_file_id.present?
  end

  def processed?
    processed_at.present?
  end

  def error_mode?
    @in_error_mode
  end

  private

  def create_order_from_imported_row!(row_importer)
    Order.create!(
      facility: facility,
      account: row_importer.account,
      user: row_importer.user,
      created_by_user: creator,
      order_import_id: id,
    )
  end

  def discard_error_report
    self.error_file = nil
    self.error_report = nil
  end

  def handle_save_clean_orders # TODO: refactor and rename
    rows_by_order_key.each do |order_key, rows|
      reset_error_mode
      processed_rows = []

      # one transaction per order_key (per order effectively)
      Order.transaction do
        processed_rows += rows.map { |row| process_row(row).to_csv }

        if error_mode?
          self.error_report += processed_rows.join("")
          result.failures += rows.length
          raise ActiveRecord::Rollback
        else
          result.successes += rows.length
          # don't write anything from this order to the error_report
        end
      end

      if !error_mode? && send_receipts?
        send_notifications([order_cache[order_key]])
      end
    end
  end

  def handle_save_nothing_on_error # TODO: refactor and rename
    Order.transaction do
      begin
        CSV.parse(upload_file.read, headers: true, skip_lines: /^,*$/).each do |row|
          row_importer = import_row(row)
          self.error_report += row_importer.row_with_errors.to_csv

          if row_importer.errors?
            result.failures += 1
          else
            result.successes += 1
          end
        end
      rescue => e
        set_error_mode
        result.failures += 1
        self.error_report += "Unable to open CSV File: #{e.message}"
      end

      raise ActiveRecord::Rollback if result.failed?
    end

    if result.succeeded?
      send_notifications(processed_orders) if send_receipts?
      discard_error_report
    end
  end

  def import_row(row) # TODO: refactor
    begin
      row_importer = OrderRowImporter.new(row, self)
      row_importer.import
    rescue => e
      ActiveSupport::Notifications.instrument("background_error",
                                              exception: e, information: "Failed to bulk import: #{upload_file_path}")
      row_importer.add_error("Failed to import row")
    end
    if row_importer.errors?
      set_error_mode
    else
      order_cache[row_importer.order_key] = row_importer.order_id
    end
    row_importer
  end

  def init_error_report
    self.error_report = OrderRowImporter.headers_to_s + "\n"
  end

  def order_cache
    @order_cache ||= OrderCache.new
  end

  def process_row(row)
    row_importer = import_row(row)
    @in_error_mode ? row_importer.row_with_errors : row
  end

  def processed_orders
    order_cache.fetch_all_orders
  end

  def reset_error_mode
    @in_error_mode = false
  end

  def rows_by_order_key # TODO: refactor
    rows = Hash.new { |hash, key| hash[key] = [] }
    CSV.parse(upload_file.read, headers: true, skip_lines: /^,*$/).each do |row|
      order_key = OrderRowImporter.order_key_for_row(row)
      rows[order_key] << row
    end
    rows
  end

  def send_notifications(orders)
    orders.each do |order|
      PurchaseNotifier.order_receipt(user: order.user, order: order).deliver_later
    end
  end

  def set_error_mode
    @in_error_mode = true
  end

  def store_error_report
    self.error_file = StoredFile.new(
      file: StringIO.new(self.error_report),
      file_content_type: "text/csv",
      file_type: "import_error",
      name: "error_report.csv",
      created_by: creator.id,
    )

    error_file.file.instance_write(:file_name, "error_report.csv")
    error_file.save!
  end

  def upload_file_path
    @upload_file_path ||= upload_file.file.path
  end

  class Result

    attr_accessor :successes, :failures

    def initialize
      self.successes = 0
      self.failures = 0
    end

    def failed?
      failures > 0
    end

    def succeeded?
      failures == 0 && successes > 0
    end

    def blank?
      successes == 0 && failures == 0
    end

    def to_h
      { successes: successes, failures: failures }
    end

  end

  class OrderCache

    def initialize
      @orders = {}
    end

    def []=(order_key, order_id)
      @orders[order_key] = order_id
    end

    def [](order_key)
      Order.find(@orders[order_key]) if @orders[order_key].present?
    end

    def fetch_all_orders
      Order.where(id: @orders.values)
    end

  end

end
