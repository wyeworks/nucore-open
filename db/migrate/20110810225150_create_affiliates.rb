# frozen_string_literal: true

class CreateAffiliates < ActiveRecord::Migration[4.2]

  def self.up
    create_table :affiliates do |t|
      t.string :name
      t.timestamps
    end

    Affiliate.create!(name: "Other")
  end

  def self.down
    drop_table :affiliates
  end

end
