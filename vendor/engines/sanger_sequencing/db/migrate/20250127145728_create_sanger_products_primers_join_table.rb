# frozen_string_literal: true

class CreateSangerProductsPrimersJoinTable < ActiveRecord::Migration[7.0]
  def change
    create_join_table :sanger_products, :primers, table_name: "san_seq_sanger_prods_primers"
  end
end
