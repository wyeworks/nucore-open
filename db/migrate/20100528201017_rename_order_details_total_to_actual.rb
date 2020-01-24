# frozen_string_literal: true

class RenameOrderDetailsTotalToActual < ActiveRecord::Migration[4.2]

  def self.up
    rename_column :order_details, :total_cost, :actual_cost
    rename_column :order_details, :total_subsidy, :actual_subsidy
  end

  def self.down
    rename_column :order_details, :actual_cost, :total_cost
    rename_column :order_details, :actual_subsidy, :total_subsidy
  end

end
