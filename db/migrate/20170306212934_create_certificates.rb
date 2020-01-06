# frozen_string_literal: true

class CreateCertificates < ActiveRecord::Migration

  def change
    create_table :nu_safety_certificates do |t|
      t.string :name, null: false
      t.datetime :deleted_at
      t.integer :deleted_by_id

      t.timestamps null: false
    end

    add_index :nu_safety_certificates, :name
    add_foreign_key :nu_safety_certificates, :users, column: :deleted_by_id
    add_index :nu_safety_certificates, :deleted_by_id
  end

end
