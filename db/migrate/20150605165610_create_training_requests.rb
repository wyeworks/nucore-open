# frozen_string_literal: true

class CreateTrainingRequests < ActiveRecord::Migration[4.2]

  def change
    create_table :training_requests do |t|
      t.references :user
      t.references :product

      t.timestamps null: false
    end
    add_index :training_requests, :user_id
    add_index :training_requests, :product_id
  end

end
