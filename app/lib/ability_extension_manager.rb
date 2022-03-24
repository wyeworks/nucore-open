# frozen_string_literal: true

# This class is used by the Ability class in order for you to customize the
# ability behavior inside of an engines. Extensions should take the ability as
# an initialization argument and implement `extend`.
#
# def extend(user, resource)
#   if user.administrator?
#     ability.can :manage, MyEngine::MyModel
#   end
# end
#
# Then, in your engine's `to_prepare` block, add it to the manager
# AbilityExtensionManager.extensions << "SplitAccounts::AbilityExtension"
#
# The order of the extensions matters as they run in the order you add them.
class AbilityExtensionManager

  def self.extensions
    @extensions ||= []
  end

  attr_reader :ability

  def initialize(ability)
    @ability = ability
  end

  def extend(user, resource)
    self.class.extensions.each do |extension|
      extension.constantize.new(ability).extend(user, resource)
    end
  end

end
