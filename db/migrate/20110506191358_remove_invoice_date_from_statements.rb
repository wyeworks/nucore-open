# frozen_string_literal: true

class RemoveInvoiceDateFromStatements < ActiveRecord::Migration[4.2]

  def self.up
    statements = Statement.all
    statements.each do |s|
      details = OrderDetail.find(:all, conditions: ["statement_id = ? AND reviewed_at IS NULL", s.id])
      details.each do |od|
        od.reviewed_at = s.invoice_date
        od.save!
      end
    end
    remove_column :statements, :invoice_date
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
