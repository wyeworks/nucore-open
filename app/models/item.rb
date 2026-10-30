# frozen_string_literal: true

class Item < Product
  has_many :item_price_policies, foreign_key: :product_id

  validates :initial_order_status_id, presence: true
end
