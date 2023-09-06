# frozen_string_literal: true

class AddProjectDatesToUmassCorumApiSpeedTypes < ActiveRecord::Migration[6.0]
  def change
    add_column :umass_corum_api_speed_types, :project_start_date, :datetime
    add_column :umass_corum_api_speed_types, :project_end_date, :datetime
  end
end
