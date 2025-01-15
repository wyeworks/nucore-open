# frozen_string_literal: true

module SangerSequencing

  class Ability

    include CanCan::Ability

    def initialize(user, facility = nil)
      return unless user

      can [:show, :create, :update, :create_sample], Submission, user: user

      if facility && user.operator_of?(facility)
        can [:index, :show], Submission
        can :manage, [Batch, BatchForm]
      end
    end

  end

end
