# frozen_string_literal: true

class AddProcessingFeeToPayments < ActiveRecord::Migration[4.2]

  def change
    add_column :payments, :processing_fee, :decimal, precision: 10, scale: 2
  end

end
