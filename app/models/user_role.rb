# frozen_string_literal: true

class UserRole < ApplicationRecord

  acts_as_paranoid

  belongs_to :user
  belongs_to :facility

  ACCOUNT_MANAGER = "Account Manager"
  ADMINISTRATOR = "Administrator"
  GLOBAL_BILLING_ADMINISTRATOR = "Global Billing Administrator"
  FACILITY_DIRECTOR = "Facility Director"
  FACILITY_ADMINISTRATOR = "Facility Administrator"
  FACILITY_STAFF = "Facility Staff"
  FACILITY_SENIOR_STAFF = "Facility Senior Staff"
  FACILITY_BILLING_ADMINISTRATOR = "Facility Billing Administrator"

  scope :facility_director, -> { where(role: FACILITY_DIRECTOR) }
  scope :director_and_admins, -> { where(role: [FACILITY_DIRECTOR, FACILITY_ADMINISTRATOR]) }

  module AssociationExtension

    def operator?(facility)
      any? { |ur| ur.facility == facility && ur.in?(facility_roles) }
    end

    def manager?(facility)
      any? { |ur| ur.facility == facility && ur.in?(facility_management_roles) }
    end

  end

  def self.account_manager
    [ACCOUNT_MANAGER]
  end

  def self.administrator
    [ADMINISTRATOR]
  end

  def self.global_billing_administrator
    [GLOBAL_BILLING_ADMINISTRATOR]
  end

  def self.facility_management_roles
    [FACILITY_DIRECTOR, FACILITY_ADMINISTRATOR]
  end

  def self.facility_roles
    facility_management_roles + [FACILITY_STAFF, FACILITY_SENIOR_STAFF, FACILITY_BILLING_ADMINISTRATOR]
  end

  def self.global_roles
    if SettingsHelper.feature_on?(:global_billing_administrator)
      account_manager + administrator + global_billing_administrator
    else
      account_manager + administrator
    end
  end

  def self.valid_roles
    global_roles + facility_roles
  end

  def self.global
    where(role: global_roles)
  end

  #
  # Assigns +role+ to +user+ for +facility+
  # [_user_]
  #   the user you want to grant permissions to
  # [_role_]
  #   one of this class' constants
  # [_facility_]
  #   the facility that you want to grant permissions on.
  #   Leave nil when creating administrators
  def self.grant(user, role, facility = nil)
    create!(user: user, role: role, facility: facility)
  end

  validates_presence_of :user_id
  validates_inclusion_of :role, in: ->(_roles) { valid_roles }, message: "is not a valid value"
  validates_uniqueness_of :role,
                          scope: [:facility_id, :user_id]
  validates_with UserRoleFacilityValidator

  def facility_role?
    self.class.facility_roles.include?(role)
  end

  def global_role?
    !facility_role?
  end

  # Supports a single item or an array of symbols (:account_manager), strings
  # both underscored ("global_billing_administrator") and title cased ("Facility Staff).
  def in?(roles)
    role.in? Array(roles).map(&:to_s).map(&:titleize)
  end

  def to_log_s
    [
      user,
      "-",
      facility_id ? facility.abbreviation : "Global",
      role,
    ].join(" ")
  end

end
