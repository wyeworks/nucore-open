# frozen_string_literal: true

class AlterPricePoliciesAddChargeFor < ActiveRecord::Migration

  def up
    add_column :price_policies, :charge_for, :string
  end

  def down
    remove_column :price_policies, :charge_for
  end

end
