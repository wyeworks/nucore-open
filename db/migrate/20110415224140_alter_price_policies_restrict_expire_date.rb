# frozen_string_literal: true

class AlterPricePoliciesRestrictExpireDate < ActiveRecord::Migration[4.2]

  def self.up
    change_column(:price_policies, :expire_date, :datetime, null: false)
  end

  def self.down
    change_column(:price_policies, :expire_date, :datetime)
  end

end
