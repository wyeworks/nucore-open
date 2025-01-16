# frozen_string_literal: true

class AddProductSangerSequencingEnabled < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :sanger_sequencing_enabled, :boolean, null: false, default: false
  end
end
