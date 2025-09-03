# frozen_string_literal: true

class StatementsInvoiceNumberUniqueIndex < ActiveRecord::Migration[7.0]
  def change
    add_index(
      :statements,
      :invoice_number,
      unique: true,
      name: "index_stmt_invoice_number",
    )
  end
end
