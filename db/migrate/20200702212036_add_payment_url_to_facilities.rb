# frozen_string_literal: true

class AddPaymentUrlToFacilities < ActiveRecord::Migration[5.2]
  def change
    change_table :facilities do |t|
      t.string :payment_url
    end
  end
end
