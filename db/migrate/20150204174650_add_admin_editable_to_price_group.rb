# frozen_string_literal: true

class AddAdminEditableToPriceGroup < ActiveRecord::Migration[4.2]

  def up
    add_column :price_groups, :admin_editable, :boolean, after: :is_internal, null: false, default: true

    (PriceGroup.globals - [PriceGroup.cancer_center]).each do |price_group|
      price_group.update_attribute(:admin_editable, false)
    end
  end

  def down
    remove_column :price_groups, :admin_editable
  end

end
