# frozen_string_literal: true

module SangerSequencing
  module Admin
    class AdminController < SangerSequencing::BaseController
      check_authorization

      # For the sake of `authorize_resource`, we want to use the sanger_ability
      # But then we we get to the view rendering we'll want the default current_ability
      def self.authorize_sanger_resource(*)
        before_action { @current_ability = sanger_ability }
        authorize_resource(*)
        before_action { @current_ability = nil }
      end

      def sanger_ability
        SangerSequencing::Ability.new(current_user, current_facility)
      end
    end
  end
end
