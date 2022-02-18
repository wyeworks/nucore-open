class AdjustPricePolicyUsageSubsidyPrecision < ActiveRecord::Migration[6.0]
  def up
    change_column :price_policies, :usage_subsidy, :decimal, precision: 16, scale: 8
  end

  def down
    change_column :price_policies, :usage_subsidy, :decimal, precision: 12, scale: 4
  end
end
