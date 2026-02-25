# frozen_string_literal: true

# There are many roles that can be assigned to users.
# Mix this module into the +User+ class to include
# convenience methods for testing the role status of users.
module Users

  module Roles

    # Creates methods #administrator?, #facility_staff?, etc.
    # Each returns true if #user_roles has the role for any facility.
    UserRole.global_roles.each do |role|
      define_method(role.gsub(/\s/, "_").downcase + "?") do
        user_roles.collect(&:role).include?(role)
      end
    end

    # Creates methods #administrator_of?, #facility_staff_of?, etc.
    # Each takes a +Facility+ as an argument.
    # Each returns true if #user_roles has the role for the given facility.
    UserRole.facility_roles.each do |role|
      define_method(role.gsub(/\s/, "_").downcase + "_of?") do |facility|
        user_roles.find { |r| r.facility == facility && r.role == role }.present?
      end
    end

    # Returns relation of facilities for which this user is staff, a director, or an admin,
    # or has been granted any granular permission.
    def operable_facilities
      if administrator?
        Facility.alphabetized
      else
        Facility
          .where(id: user_roles.where(role: UserRole.facility_roles).select(:facility_id))
          .or(Facility.where(id: facility_user_permissions.select(:facility_id)))
          .alphabetized
      end
    end

    def facility_staff_or_manager_of_any_facility?
      user_roles.find { |r| [UserRole::FACILITY_DIRECTOR, UserRole::FACILITY_ADMINISTRATOR, UserRole::FACILITY_SENIOR_STAFF, UserRole::FACILITY_STAFF].include?(r.role) }.present?
    end

    def facility_staff_or_manager_of?(facility)
      manager_of?(facility) || facility_staff_of?(facility)
    end

    # Returns relation of facilities for which this user is a director or admin
    def manageable_facilities
      if administrator? || global_billing_administrator?
        Facility.alphabetized
      else
        user_roles_facilities.alphabetized.where(user_roles: { role: UserRole.facility_management_roles })
      end
    end

    def operator_of?(facility)
      return false if facility.blank?
      user_roles.operator?(facility) || administrator?
    end

    def manager_of?(facility)
      return false if facility.blank?
      user_roles.manager?(facility) || administrator?
    end

    def facility_staff_of?(facility)
      return false if facility.blank?

      user_roles.staff?(facility) || administrator?
    end

    def can_override_restrictions?(product)
      operator_of? product.facility
    end

    def cannot_override_restrictions?(product)
      !operator_of?(product.facility)
    end

    # Creates methods #purchaser_of?, #owner_of?, etc.
    # Each takes an +Account+ as an argument.
    # Each returns true if #account_users has the user_role for the given account.
    AccountUser.user_roles.each do |role|
      define_method(role.gsub(/\s/, "_").downcase + "_of?") do |account|
        account_users.find { |au| au.account == account && au.user_role == role }.present?
      end
    end

    def account_administrator_of?(account)
      owner_of?(account) || business_administrator_of?(account)
    end

  end

end
