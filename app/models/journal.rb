# frozen_string_literal: true

class Journal < ApplicationRecord
  module Overridable
    def create_spreadsheet
      rows = journal_rows
      return false if rows.empty?

      output_file = JournalSpreadsheet.write_journal_entry(rows, output_file: temp_file.path)
      # add/import journal spreadsheet
      status      = add_spreadsheet(output_file)
      # remove temp file
      begin
        File.unlink(temp_file.path)
      rescue
        nil
      end
      status
    end

    private

    def temp_file
      @temp_file ||= File.new(spreadsheet_filename, "w")
    end

    def spreadsheet_filename
      Rails.root.join("tmp/journal.spreadsheet.#{Time.current.strftime('%Y%m%dT%H%M%S')}.xls")
    end
  end

  include DownloadableFile
  include Overridable

  attr_accessor :order_details_for_creation

  attribute :defer_journal_row_creation, default: false

  belongs_to :facility, optional: true
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by

  has_many :journal_rows

  validates   :reference, :updated_by, presence: { on: :update }
  validates   :created_by, presence: true
  validates   :journal_date, presence: true
  validates :reference, length: { maximum: 50 }
  validate :journal_date_cannot_be_in_future, if: :journal_date?
  validate :must_have_order_details, on: :create, if: :order_details_for_creation
  validate :must_not_span_fiscal_years, on: :create, if: :should_check_fiscal_years?
  validate :journal_date_cannot_be_before_last_fulfillment, on: :create, if: :has_order_details_for_creation?
  validate :must_not_span_facilities, on: :create, if: :has_order_details_for_creation?
  validates_with JournalDateMustBeAfterCutoffs, on: :create
  before_validation :set_facility_id, on: :create, if: :has_order_details_for_creation?
  after_create :create_new_journal_rows!, if: -> { has_order_details_for_creation? && !defer_journal_row_creation }

  scope :pending, -> { where(is_successful: nil) }

  def self.for_facilities(facilities)
    where(facility_id: facilities.map(&:id))
  end

  # This pseudo-association cannot be a `has_many :through` because that will
  # always INNER JOIN journal_rows, which for split accounts will return
  # duplicate OrderDetails. And we can't add `-> { distinct }` as the scope
  # because Oracle has problems with `DISTINCT *` when one of the columns is a
  # CLOB (e.g. the notes field).
  def order_details
    OrderDetail.where(id: journal_rows.select(:order_detail_id).distinct)
  end

  def create_journal_rows!(order_details)
    builder = JournalRowBuilder.new(self, order_details).create
    builder.errors.uniq
  end

  def amount
    # only sum positive amounts since this is a double entry journal
    journal_rows.inject(0) { |sum, row| sum + (row.amount > 0 ? row.amount : 0) }
  end

  def open?
    is_successful.nil?
  end

  def add_spreadsheet(file_path)
    return false unless File.exist?(file_path)

    update_attribute(:file, File.open(file_path))
  end

  def status_string
    if is_successful.nil?
      "Pending"
    elsif !is_successful?
      "Failed"
    else
      reconciled? ? "Successful, reconciled" : "Successful, not reconciled"
    end
  end

  def reconciled?
    if is_successful.nil?
      false
    elsif !successful?
      true
    else
      OrderDetail.where(journal_id: id).where.not(state: "reconciled").empty?
    end
  end

  def order_details_span_fiscal_years?(order_details)
    d = order_details.first.fulfilled_at
    start_fy = SettingsHelper.fiscal_year_beginning(d)
    end_fy = SettingsHelper.fiscal_year_end(d)
    order_details.each do |od|
      return true if od.fulfilled_at < start_fy || od.fulfilled_at >= end_fy
    end
    false
  end

  def submittable?
    successful? && !reconciled?
  end

  def successful? # TODO: Keep until we rename the is_successful column to successful
    is_successful?
  end

  def to_log_s
    "Journal ##{id}"
  end

  delegate :to_s, to: :id

  def create_new_journal_rows
    row_errors = create_journal_rows!(@order_details_for_creation)
    return unless row_errors.any?

    row_errors.each { |e| errors.add(:base, e) }
    destroy # so it's treated as a new record
  end

  def create_new_journal_rows!
    create_new_journal_rows

    raise ActiveRecord::RecordInvalid.new(self) if errors.present?
  end

  private

  def should_check_fiscal_years?
    !SettingsHelper.feature_on?("billing.journals_may_span_fiscal_years") && has_order_details_for_creation?
  end

  def has_order_details_for_creation?
    @order_details_for_creation.try(:any?)
  end

  def must_not_span_fiscal_years
    errors.add(:base, :fiscal_year_span) if order_details_span_fiscal_years?(@order_details_for_creation)
  end

  def must_have_order_details
    errors.add(:base, :no_orders) if @order_details_for_creation.none?
  end

  def journal_date_cannot_be_in_future
    errors.add(:journal_date, :cannot_be_in_future) if journal_date > Time.zone.now.end_of_day
  end

  def journal_date_cannot_be_before_last_fulfillment
    return unless journal_date.present?

    last_fulfilled = @order_details_for_creation.collect(&:fulfilled_at).max
    errors.add(:journal_date, :cannot_be_before_last_fulfillment) if journal_date.end_of_day < last_fulfilled
  end

  def must_not_span_facilities
    errors.add(:base, :multiple_facilities) if order_details_for_creation_facility_ids.many?
  end

  def set_facility_id
    self.facility_id = order_details_for_creation_facility_ids.first
  end

  def order_details_for_creation_facility_ids
    @order_details_for_creation.map { |od| od.order.facility_id }.uniq
  end
end
