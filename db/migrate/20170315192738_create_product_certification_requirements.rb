# frozen_string_literal: true

class CreateProductCertificationRequirements < ActiveRecord::Migration

  def change
    create_table :nu_product_cert_requirements do |t|
      t.references :product, index: true, foreign_key: true
      t.references :nu_safety_certificate, index: true, foreign_key: true
      t.datetime :deleted_at
      t.integer :deleted_by_id

      t.timestamps null: false
    end
  end

end
