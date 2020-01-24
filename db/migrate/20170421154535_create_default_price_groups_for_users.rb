# frozen_string_literal: true

class CreateDefaultPriceGroupsForUsers < ActiveRecord::Migration[4.2]

  def up
    User.find_each(&:create_default_price_group!)
  end

  def down
    UserPriceGroupMember.where(price_group: [PriceGroup.base, PriceGroup.external]).delete_all
  end

end
