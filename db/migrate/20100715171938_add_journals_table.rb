# frozen_string_literal: true

class AddJournalsTable < ActiveRecord::Migration[4.2]

  def self.up
    create_table :journals do |t|
      t.references :facility,       null: false
      t.string     :reference,      null: true, limit: 50
      t.string     :description,    null: true, limit: 200
      t.boolean    :is_successful,  null: true
      t.integer    :created_by,     null: false
      t.datetime   :created_at,     null: false
      t.integer    :updated_by,     null: true
      t.datetime   :updated_at,     null: true
    end

    create_table :journaled_accounts do |t|
      t.references :journal,        null: false
      t.references :account,        null: false
    end
  end

  def self.down
    drop_table :journaled_accounts
    drop_table :journals
  end

end
