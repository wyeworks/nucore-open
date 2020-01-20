# frozen_string_literal: true

class AddSubaffiliatesEnabledFlagToAffiliates < ActiveRecord::Migration[4.2]

  def up
    add_column :affiliates, :subaffiliates_enabled, :boolean, default: false, null: false
    Affiliate.where(name: "Other").update_all(subaffiliates_enabled: true)
  end

  def down
    remove_column :affiliates, :subaffiliates_enabled
  end

end
