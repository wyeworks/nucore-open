# frozen_string_literal: true

class AddOrderDetailStatusesTable < ActiveRecord::Migration[4.2]

  def self.up
    create_table :order_detail_statuses do |t|
      t.references :order_detail, null: false
      t.references :order_status, null: false
      t.datetime   :updated_at,   null: false
      t.integer    :updated_by,   null: false
    end
    execute "ALTER TABLE order_detail_statuses add CONSTRAINT fk_order_details  FOREIGN KEY (order_detail_id) REFERENCES order_details  (id)"
    execute "ALTER TABLE order_detail_statuses add CONSTRAINT fk_order_statuses FOREIGN KEY (order_status_id) REFERENCES order_statuses (id)"
  end

  def self.down
    drop_table :order_detail_statuses
  end

end
