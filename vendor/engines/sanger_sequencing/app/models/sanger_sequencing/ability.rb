# frozen_string_literal: true

module SangerSequencing

  class Ability

    include CanCan::Ability

    def initialize(user, facility = nil)
      return unless user

      can [:show, :create, :update, :create_sample], Submission, user: user

      if facility && (user.operator_of?(facility) || granted_product_management?(user, facility))
        can [:index, :show], Submission
        can :manage, [Batch, BatchForm, Primer]
      end
    end

    private

    def granted_product_management?(user, facility)
      return false unless SettingsHelper.feature_on?(:granular_permissions)

      permission = user.facility_user_permissions.find_by(facility: facility)
      permission&.read_access? && permission.product_management?
    end

  end

end
