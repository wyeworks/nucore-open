# frozen_string_literal: true

class BaseRateRename < ActiveRecord::Migration[4.2]

  def self.up
    # unscoped to allow migrations to run despite acts_as_paranoid
    # https://github.com/rubysherpas/paranoia/issues/226
    pg = PriceGroup.unscoped.find_by(name: "Northwestern Base Rate")
    pg.update_attribute(:name, "Base Rate") if pg
  end

  def self.down
    # unscoped to allow migrations to run despite acts_as_paranoid
    # https://github.com/rubysherpas/paranoia/issues/226
    pg = PriceGroup.unscoped.find_by(name: "Base Rate")
    pg.update_attribute(:name, "Northwestern Base Rate") if pg
  end

end
