# frozen_string_literal: true

class BaseRateRename < ActiveRecord::Migration[4.2]

  def self.up
    pg = PriceGroup.find_by(name: "Northwestern Base Rate")
    pg.update_attribute(:name, "Base Rate") if pg
  end

  def self.down
    pg = PriceGroup.find_by(name: "Base Rate")
    pg.update_attribute(:name, "Northwestern Base Rate") if pg
  end

end
