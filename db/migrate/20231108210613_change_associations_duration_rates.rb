# frozen_string_literal: true

class ChangeAssociationsDurationRates < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      DELETE FROM duration_rates
    SQL

    change_table :duration_rates do |t|
      t.references :price_policy
    end

    remove_column :duration_rates, :price_group_id
  end

  def down
    change_table :duration_rates do |t|
      t.references :price_group
    end

    remove_column :duration_rates, :price_policy_id
  end
end
