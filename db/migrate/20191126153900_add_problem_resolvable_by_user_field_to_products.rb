# frozen_string_literal: true

class AddProblemResolvableByUserFieldToProducts < ActiveRecord::Migration[5.0]

  def change
    change_table :products do |t|
      t.boolean :problems_resolvable_by_user, null: false, default: false
    end
  end

end
