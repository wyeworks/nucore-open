module SecureRooms

  module AccessRules

    class DenyAllRule < BaseRule

      def evaluate
        deny!(:rules_failed)
      end

    end

  end

end
