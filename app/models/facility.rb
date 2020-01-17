# frozen_string_literal: true

class Facility < ApplicationRecord

  before_validation :set_journal_mask, on: :create

  has_many :bundles, inverse_of: :facility
  has_many :director_and_admin_roles, -> { merge(UserRole.director_and_admins) }, class_name: "UserRole"
  has_many :director_and_admins, -> { distinct }, through: :director_and_admin_roles, source: :user
  has_many :facility_accounts
  has_many :instruments, inverse_of: :facility
  has_many :items, inverse_of: :facility
  has_many :journals
  has_many :non_instrument_products, -> { where.not(type: "Instrument").alphabetized }, class_name: "Product", inverse_of: :facility
  has_many :products
  has_many :order_details, through: :products
  has_many :order_imports, dependent: :destroy
  has_many :orders, -> { purchased }
  has_many :schedules
  has_many :services, inverse_of: :facility
  has_many :statements
  has_many :timed_services, inverse_of: :facility
  has_many :training_requests, through: :products
  has_many :user_roles, dependent: :destroy
  has_many :users, -> { distinct }, through: :user_roles

  validates_presence_of :name, :short_description, :abbreviation
  validate_url_name :url_name
  validates_uniqueness_of :abbreviation, :journal_mask, case_sensitive: false
  validates_format_of :abbreviation, with: /\A[a-zA-Z\d\-\.\s]+\z/, message: "may include letters, numbers, hyphens, spaces, or periods only"
  validates_format_of :journal_mask, with: /\AC\d{2}\z/, message: "must be in the format C##"

  validates :order_notification_recipient,
            email_format: true,
            if: proc { |facility| facility.order_notification_recipient.present? }

  validates :short_description,
            length: { maximum: 300 },
            if: -> { SettingsHelper.feature_on?(:limit_short_description) }

  delegate :in_dispute, to: :order_details, prefix: true

  scope :active, -> { where(is_active: true) }
  scope :alphabetized, -> { order(:name) }

  cattr_accessor(:facility_account_validators) { [] }

  def can_pay_with_account?(account)
    return true unless account

    facility_account_validators.all? { |validator| validator.new(self, account).valid? }
  end

  def self.cross_facility
    @cross_facility ||=
      new(url_name: "all", name: "Cross-Facility", abbreviation: "ALL", is_active: true)
  end

  def destroy
    # TODO: can you ever delete a facility? Currently no.
    # super
  end

  def order_statuses
    OrderStatus.for_facility(self)
  end

  def price_groups
    PriceGroup.for_facility(self)
  end

  def to_param
    if errors[:url_name].empty?
      url_name
    else
      url_name_was
    end
  end

  def status_string
    is_active? ? "Active" : "Inactive"
  end

  def has_contact_info?
    address || phone_number || fax_number || email
  end

  def has_pending_journals?
    pending_facility_ids = Journal.facility_ids_with_pending_journals
    if cross_facility?
      pending_facility_ids.any?
    else
      pending_facility_ids.member?(id)
    end
  end

  def cross_facility?
    eql? self.class.cross_facility
  end

  def single_facility?
    !cross_facility?
  end

  def to_s
    "#{name} (#{abbreviation})"
  end

  def problem_plain_order_details
    complete_problem_order_details.item_and_service_orders
  end

  def problem_reservation_order_details
    complete_problem_order_details.reservations
  end

  def complete_problem_order_details
    order_details.problem_orders.complete
  end

  def schedules_for_timeline(instruments_association)
    schedules
    .active
    .includes(instruments_association => [:alert, :current_offline_reservations, :relay, :schedule_rules])
    .order(:name)
  end

  private

  def set_journal_mask
    f = Facility.all.order(journal_mask: :desc).first
    self.journal_mask = if f&.journal_mask&.match(/^C(\d{2})$/)
                          format("C%02d", Regexp.last_match(1).to_i + 1)
                        else
                          "C01"
                        end
  end

end
