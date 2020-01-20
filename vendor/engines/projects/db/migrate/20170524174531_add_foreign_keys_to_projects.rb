# frozen_string_literal: true

class AddForeignKeysToProjects < ActiveRecord::Migration[4.2]

  def change
    add_index :order_details, :project_id
  end

end
