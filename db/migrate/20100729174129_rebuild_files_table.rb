# frozen_string_literal: true

class RebuildFilesTable < ActiveRecord::Migration[4.2]

  def self.up
    drop_table :files
    create_table :files do |t|
      t.references :order_detail,    null: true
      t.references :product,         null: true
      t.string     :name,            null: false, limit: 200
      t.string     :file_type,       null: false, limit: 50
      t.string     :content_type,    null: false, limit: 50
      t.integer    :created_by,      null: false
      t.datetime   :created_at,      null: false
    end
    execute "ALTER TABLE files ADD CONSTRAINT fk_files_od FOREIGN KEY (order_detail_id) REFERENCES order_details (id)"
    execute "ALTER TABLE files ADD CONSTRAINT fk_files_product FOREIGN KEY (product_id) REFERENCES products (id)"
  end

  def self.down
    drop_table :files
  end

end
