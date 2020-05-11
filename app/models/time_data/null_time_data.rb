# frozen_string_literal: true

module TimeData

  class NullTimeData

    def order_completable?
      true
    end

    def problem_description_key
    end

    # Gives us both `blank?` and `present?`
    def blank?
      true
    end

    def force_dirty!
    end

  end

end
