# frozen_string_literal: true

class RemoveFacilityAffiliateId < ActiveRecord::Migration[4.2]

  def self.up
    remove_column(:facilities, :pers_affiliate_id)
  end

  def self.down
    add_column(:facilities, :pers_affiliate_id, :integer)
  end

end
