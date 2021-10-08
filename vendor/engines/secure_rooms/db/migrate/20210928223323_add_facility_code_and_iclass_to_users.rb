# frozen_string_literal: true

class AddFacilityCodeAndIclassToUsers < ActiveRecord::Migration[5.2]

  def change
    add_column :users, :i_class_number, :string
    add_index :users, :i_class_number, unique: true
    remove_index :users, [:card_number]
    add_index :users, [:card_number], unique: true
  end

end
