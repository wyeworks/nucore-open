# frozen_string_literal: true

class AddFieldsToUmassCorumApiSpeedTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :umass_corum_api_speed_types, :setid, :string
    add_column :umass_corum_api_speed_types, :speedchart_desc, :string
    add_column :umass_corum_api_speed_types, :hr_acct_cd, :string
  end
end
