# frozen_string_literal: true

class UserPreferenceOption
  def initialize(user)
    @user = user
  end

  def name
    # "My Awesome Option"
    raise NotImplementedError
  end

  def visible_to_user?
    # returns a boolean
    raise NotImplementedError
  end

  def options_for_user
    # ["Option 1", "Option 2"]
    raise NotImplementedError
  end

  def default_value
    # "Option 1"
    raise NotImplementedError
  end
end
