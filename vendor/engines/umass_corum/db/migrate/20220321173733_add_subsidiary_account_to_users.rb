# frozen_string_literal: true

class AddSubsidiaryAccountToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :subsidiary_account, :boolean, default: false
  end
end
