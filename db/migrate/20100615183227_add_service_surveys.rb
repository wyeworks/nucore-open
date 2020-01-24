# frozen_string_literal: true

class AddServiceSurveys < ActiveRecord::Migration[4.2]

  def self.up
    create_table :service_surveys do |t|
      t.references  :service
      t.references  :survey
      t.boolean     :active, default: false
      t.datetime    :active_at

      t.timestamps
    end
  end

  def self.down
    drop_table :service_surveys
  end

end
