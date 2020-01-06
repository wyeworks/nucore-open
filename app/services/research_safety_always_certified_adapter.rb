# frozen_string_literal: true

# This is the default adapter and should only be used for demo/initial implementation
# purposes. It should be replaced by an actual call to an API or other lookup.
class ResearchSafetyAlwaysCertifiedAdapter

  def initialize(user)
    @user = user
  end

  def certified?(certificate)
    true
  end

end
