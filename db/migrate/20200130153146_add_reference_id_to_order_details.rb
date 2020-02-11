class AddReferenceIdToOrderDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :order_details, :reference_id, :string
  end
end
