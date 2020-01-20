# frozen_string_literal: true

class AddServiceSurveysPreviewCode < ActiveRecord::Migration[4.2]

  def self.up
    change_table :service_surveys do |t|
      t.string :preview_code, length: 50
    end
  end

  def self.down
    remove_column :service_surveys, :preview_code
  end

end
