# frozen_string_literal: true

require "rails_helper"

RSpec.describe PriceGroupDiscount, type: :model do
  subject(:price_group_discount) { build(:price_group_discount, :blank) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:discount_percent) }
    it { is_expected.to validate_numericality_of(:discount_percent).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:discount_percent).is_less_than(100) }
  end
end
