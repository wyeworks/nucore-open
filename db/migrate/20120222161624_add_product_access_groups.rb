# frozen_string_literal: true

class AddProductAccessGroups < ActiveRecord::Migration[4.2]

  def self.up
    create_table :product_access_groups do |t|
      t.references :product, null: false
      t.string :name
      t.timestamps
    end

    # have to use an abbreviated version of the name for oracle
    # because it only allows a maximum of 30 characters
    create_table :product_access_schedule_rules, id: false do |t|
      t.references :product_access_group, null: false
      t.references :schedule_rule, null: false
    end
    add_column :product_users, :product_access_group_id, :integer
  end

  def self.down
    drop_table :product_access_groups
    drop_table :product_access_schedule_rules
    remove_column :product_users, :product_access_group_id
  end

end
