# frozen_string_literal: true

class AddContactEmailToProduct < ActiveRecord::Migration[4.2]

  def self.up
    add_column :products, :contact_email, :string
  end

  def self.down
    remove_column :products, :contact_email
  end

end
