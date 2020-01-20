# frozen_string_literal: true

class DropAmountFromStatementRow < ActiveRecord::Migration[4.2]

  def up
    remove_column :statement_rows, :amount
  end

  def down
    add_column :statement_rows, :amount, :decimal, precision: 10, scale: 2,
                                                   null: true, after: :statement_id

    StatementRow.all.each do |statement_row|
      statement_row.update_attributes(amount: statement_row.order_detail.total)
    end

    change_column :statement_rows, :amount, :decimal, precision: 10, scale: 2,
                                                      null: false
  end

end
