# frozen_string_literal: true

module QuietStrongParams

  # Generally we want to protect ourselves against forgetting to add new fields to strong params.
  # However, for some cases (i.e. things coming in from engines, etc) this is unnecessarily complicated.
  # In these cases, we prefer to implicitly drop the extra params without raising exceptions or needing
  # to enumerate all the parameters.

  def self.with_dropped_params
    old_value = ActionController::Parameters.action_on_unpermitted_parameters
    ActionController::Parameters.action_on_unpermitted_parameters = :log
    block_return = yield
    ActionController::Parameters.action_on_unpermitted_parameters = old_value
    block_return
  end

end
