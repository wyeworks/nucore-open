# frozen_string_literal: true

class AlterAccountTransactionsAddFields < ActiveRecord::Migration[4.2]

  def self.up
    execute "DELETE FROM account_transactions"
    remove_column :account_transactions, :balance
    add_column :account_transactions, :transaction_type, :string,   null: false, limit: 50
    add_column :account_transactions, :finalized_at,     :datetime, null: true
    add_column :account_transactions, :order_detail_id,  :integer,  null: true
    execute "ALTER TABLE account_transactions add CONSTRAINT fk_act_trans_ord_dets FOREIGN KEY (order_detail_id) REFERENCES order_details (id)"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
