# frozen_string_literal: true

class PriceGroupPresenter < SimpleDelegator
  def long_name
    return name if facility.blank?

    "#{name}, #{facility}"
  end
end
