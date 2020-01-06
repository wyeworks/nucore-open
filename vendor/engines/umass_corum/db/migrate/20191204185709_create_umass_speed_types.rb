# frozen_string_literal: true

class CreateUmassSpeedTypes < ActiveRecord::Migration[5.0]

  def change
    create_table :umass_corum_api_speed_types do |t|
      t.string :speed_type, null: false, index: { unique: true }
      t.boolean :active, null: false
      t.integer :version
      t.string :clazz # AR has problems with columns named "class"
      t.string :dept_desc
      t.string :dept_id
      t.string :fund_code
      t.string :fund_desc
      t.string :manager_hr_emplid
      t.string :program_code
      t.string :project_desc
      t.string :project_id
      t.datetime :date_added
      t.datetime :date_removed
      t.string :error_desc
      t.timestamps
    end
  end

end
