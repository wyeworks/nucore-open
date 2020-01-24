# frozen_string_literal: true

class ChangeOrderDetailStatus < ActiveRecord::Migration[4.2]

  def self.up
    add_column :order_details, :order_status_id, :integer, null: true

    begin
      execute "ALTER TABLE order_details add CONSTRAINT fk_order_statuses FOREIGN KEY (order_status_id) REFERENCES order_statuses (id)"
    rescue => e
    end

    ## this would work if oracle wasn't stupid
    # execute "UPDATE order_details od SET od.order_status_id = (SELECT * FROM (SELECT order_status_id FROM order_detail_statuses ods WHERE ods.order_detail_id = od.id ORDER BY ods.created_at DESC ) WHERE ROWNUM <= 1)"

    ## so instead we do this
    OrderDetail.find_each do |od|
      ods = OrderDetailStatus.find(:first, conditions: { order_detail_id: od.id }, order: "created_at DESC")
      execute "UPDATE order_details SET order_status_id = #{ods.order_status_id}"
    end

    change_column :order_details, :order_status_id, :integer, null: false
    drop_table :order_detail_statuses
    remove_column :order_details, :status
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
