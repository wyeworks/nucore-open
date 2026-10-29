# frozen_string_literal: true

class AddFacilityNotice < ActiveRecord::Migration[5.0]
  def change
    add_column :facilities, :banner_notice, :text
  end
end
