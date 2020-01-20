# frozen_string_literal: true

class AddConstraintToOrderDetails < ActiveRecord::Migration[4.2]

  def self.up
    execute "ALTER TABLE order_details ADD CONSTRAINT fk_od_accounts FOREIGN KEY (account_id) REFERENCES accounts (id)"
  end

  def self.down
    execute "ALTER TABLE order_details DROP CONSTRAINT fk_od_accounts"
  end

end
