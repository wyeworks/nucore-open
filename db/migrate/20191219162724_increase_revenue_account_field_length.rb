# frozen_string_literal: true

class IncreaseRevenueAccountFieldLength < ActiveRecord::Migration[5.0]

  def up
    change_column :journal_rows, :account, :string, limit: nil
  end

  def down
    change_column :journal_rows, :account, :string, limit: 5
  end

end
