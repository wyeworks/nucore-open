# frozen_string_literal: true

class AddFacilityToOrderImport < ActiveRecord::Migration[4.2]

  def up
    add_column :order_imports, :facility_id, :integer, after: :id
    add_foreign_key :order_imports, :facilities, name: "fk_order_imports_facilities"
    add_index :order_imports, ["facility_id"], name: "i_order_imports_facility_id"

    orders_for_facility_backfill.each do |order|
      order.order_import.update_attribute(:facility_id, order.facility_id)
    end
  end

  def down
    remove_foreign_key :order_imports, name: "fk_order_imports_facilities"
    remove_index :order_imports, name: "i_order_imports_facility_id"
    remove_column :order_imports, :facility_id
  end

  private

  def orders_for_facility_backfill
    Order.find_by_sql("
      SELECT
        DISTINCT(order_import_id), facility_id
      FROM
        orders
      WHERE
        order_import_id IS NOT NULL
    ")
  end

end
