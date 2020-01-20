# frozen_string_literal: true

class AlterPricePolicies < ActiveRecord::Migration[4.2]

  def self.up
    remove_column(:price_policies, :reservation_window)
    remove_column(:price_policies, :restrict_purchase)
    add_column(:price_policies, :expire_date, :datetime)
    PricePolicy.reset_column_information

    PricePolicy.all.each do |pp|
      start_date = pp.start_date
      expire_date = Date.strptime("#{start_date.year}-8-31")
      expire_date = Date.strptime("#{start_date.year + 1}-8-31") if start_date >= expire_date

      # for some reason ActiveRecord attribute set and save will not work
      execute("UPDATE price_policies SET expire_date=TO_DATE('#{expire_date}') WHERE id=#{pp.id}")
    end
  end

  def self.down
    remove_column(:price_policies, :expire_date)
    add_column(:price_policies, :reservation_window, :integer)
    add_column(:price_policies, :restrict_purchase, :boolean)
  end

end
