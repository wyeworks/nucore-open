# frozen_string_literal: true

class AddPhoneNumberToUsers < ActiveRecord::Migration[5.2]
  def change
    change_table :users do |t|
      t.string :phone_number
    end
  end
end
