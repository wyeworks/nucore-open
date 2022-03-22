# frozen_string_literal: true

class AddSubsidiaryAccountToUsers < ActiveRecord::Migration[6.0]
  def change
    remove_index :users, :umass_emplid
    add_column :users, :subsidiary_account, :boolean, default: false
  end
end
