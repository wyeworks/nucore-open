module TimeData

  class RequiredTimeData

    include TextHelpers::Translation

    def order_completable?
      false
    end

    def problem_description
      text(:actual_usage_missing)
    end

    def translation_scope
      "activerecord.models.time_data.required_time_data"
    end

    # Gives us both `blank?` and `present?`
    def blank?
      true
    end

  end

end
