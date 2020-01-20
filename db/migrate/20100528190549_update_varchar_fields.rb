# frozen_string_literal: true

class UpdateVarcharFields < ActiveRecord::Migration[4.2]

  def self.up
    change_column :facilities, :url_name,      :string, limit: 50,  null: false
    change_column :facilities, :account,       :string, limit: 50,  null: false

    add_column    :facilities, :description_c, :text, null: true
    execute "UPDATE facilities SET description_c = description"
    remove_column :facilities, :description
    rename_column :facilities, :description_c, :description

    change_column :accounts, :type,            :string, limit: 50,  null: false
    change_column :accounts, :account_number,  :string, limit: 50,  null: false
    change_column :accounts, :description,     :string, limit: 50,  null: false

    change_column :order_statuses, :name,      :string, limit: 50,  null: false

    change_column :products, :type,            :string, limit: 50,  null: false
    change_column :products, :name,            :string, limit: 200, null: false
    change_column :products, :url_name,        :string, limit: 50,  null: false
    change_column :products, :unit_size,       :string, limit: 50,  null: true
    change_column :products, :relay_ip,        :string, limit: 15,  null: true

    change_column :price_groups, :name,        :string, limit: 50,  null: false

    change_column :price_group_members, :type, :string, limit: 50,  null: false

    change_column :price_policies, :type,      :string, limit: 50,  null: false
  end

  def self.down
    change_column :facilities, :account,       :string, limit: 100, null: false

    add_column    :facilities, :description_v, :varchar, limit: 4000, null: true
    execute "UPDATE facilities SET description_v = description"
    remove_column :facilities, :description
    rename_column :facilities, :description_v, :description

    change_column :accounts, :type,            :string, limit: 200,  null: false
    change_column :accounts, :account_number,  :string, limit: 100,  null: false
    change_column :accounts, :description,     :string, limit: 200,  null: false

    change_column :order_statuses, :name,      :string, limit: 200,  null: false

    change_column :products, :type,            :string, limit: 200,  null: false

    change_column :price_groups, :name,        :string, limit: 200,  null: false

    change_column :price_group_members, :type, :string, limit: 200,  null: false

    change_column :price_policies, :type,      :string, limit: 200,  null: false
  end

end
