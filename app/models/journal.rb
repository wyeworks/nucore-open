# frozen_string_literal: true

require "set"

class Journal < ApplicationRecord

  class CreationError < NUCore::Error; end

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

  belongs_to :facility
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by

  has_many :journal_rows

  # _order_details is used for building associations, and may contain duplicates.
  # Consider this private. Use order_details instead.
  has_many :_order_details, class_name: "OrderDetail", through: :journal_rows, source: :order_detail

  validates_presence_of   :reference, :updated_by, on: :update
  validates_presence_of   :created_by
  validates_presence_of   :journal_date
  validates_length_of     :reference, maximum: 50
  validate :journal_date_cannot_be_in_future, if: :journal_date?
  validate :must_have_order_details, on: :create, if: :order_details_for_creation
  validate :must_not_span_fiscal_years, on: :create, if: :should_check_fiscal_years?
  validate :journal_date_cannot_be_before_last_fulfillment, on: :create, if: :has_order_details_for_creation?
  validates_with JournalDateMustBeAfterCutoffs, on: :create
  before_validation :set_facility_id, on: :create, if: :has_order_details_for_creation?
  after_create :create_new_journal_rows, if: :has_order_details_for_creation?

  # Digs up journals pertaining to the passed in facilities
  #
  # == Parameters
  #
  # facilities::
  #   enumerable of facilities (usually ones which the user has access to)
  #
  # include_multi::
  #   include multi-facility journals in the results?
  def self.for_facilities(facilities, include_multi = false)
    allowed_ids = facilities.collect(&:id)

    if include_multi
      Journal.includes(journal_rows: { order_detail: :order }).references(:order).where("orders.facility_id IN (?)", allowed_ids).select("journals.*")
    else
      Journal.where(facility_id: allowed_ids)
    end
  end

  # TODO: Is it posible to have a cross-facility journal? If not, there are lots
  # of specs and other logic that do allow it.
  def self.facility_ids_with_pending_journals
    Journal.joins(_order_details: :order).where(is_successful: nil).distinct.pluck("orders.facility_id")
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

  def facility_ids
    if facility_id?
      [facility_id]
    else
      _order_details.joins(:order)
                    .select("orders.facility_id")
                    .collect(&:facility_id)
                    .distinct
    end
  end

  def facility_abbreviations
    Facility.where(id: facility_ids).collect(&:abbreviation)
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
    elsif is_successful? == false
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

  delegate :to_s, to: :id

  private

  def should_check_fiscal_years?
    !SettingsHelper.feature_on?(:journals_may_span_fiscal_years) && has_order_details_for_creation?
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

  def set_facility_id
    self.facility_id = if @order_details_for_creation.collect { |od| od.order.facility_id }.uniq.size > 1
                         raise CreationError, "Cannot create a cross facility journal"
                       else
                         @order_details_for_creation.first.order.facility_id
                       end
  end

  def create_new_journal_rows
    row_errors = create_journal_rows!(@order_details_for_creation)
    if row_errors.any?
      row_errors.each { |e| errors.add(:base, e) }
      destroy # so it's treated as a new record
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

end
