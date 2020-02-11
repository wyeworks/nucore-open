# frozen_string_literal: true

class AddTokenToSecureRoom < ActiveRecord::Migration[4.2]

  class Product < ActiveRecord::Base
  end

  def change
    add_column :products, :dashboard_token, :string
    add_index :products, :dashboard_token

    Product.reset_column_information
    Product.where(type: "SecureRoom").find_each { |room| room.update_column(:dashboard_token, SecureRandom.uuid) }
  end

end
