# frozen_string_literal: true

class AddActiveFlagToProjects < ActiveRecord::Migration[4.2]

  def change
    add_column :projects, :active, :boolean, null: false, default: true
  end

end
