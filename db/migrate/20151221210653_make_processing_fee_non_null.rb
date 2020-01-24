# frozen_string_literal: true

class MakeProcessingFeeNonNull < ActiveRecord::Migration[4.2]

  def up
    change_column :payments, :processing_fee, :decimal, precision: 10, scale: 2, null: false, default: 0
  end

  def down
    change_column :payments, :processing_fee, :decimal, precision: 10, scale: 2, null: true, default: nil
  end

end
