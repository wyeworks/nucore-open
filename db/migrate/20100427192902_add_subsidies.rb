# frozen_string_literal: true

class AddSubsidies < ActiveRecord::Migration[4.2]

  def self.up
    add_column :price_policies, :usage_subsidy, :decimal, precision: 9, scale: 2
    add_column :price_policies, :reservation_subsidy, :decimal, precision: 9, scale: 2
    add_column :price_policies, :overage_subsidy, :decimal, precision: 9, scale: 2
  end

  def self.down
    remove_column :price_policies, :usage_subsidy
    remove_column :price_policies, :reservation_subsidy
    remove_column :price_policies, :overage_subsidy
  end

end
