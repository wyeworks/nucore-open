# frozen_string_literal: true

module TimeData
  class RequiredTimeData
    def order_completable?
      false
    end

    def problem_description_key
      :missing_actuals
    end

    # Gives us both `blank?` and `present?`
    def blank?
      true
    end
  end
end
