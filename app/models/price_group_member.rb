# frozen_string_literal: true

class PriceGroupMember < ApplicationRecord

  belongs_to :price_group
  belongs_to :price_group_with_deleted, -> { with_deleted }, foreign_key: :price_group_id, class_name: "PriceGroup"
  delegate :facility, to: :price_group_with_deleted

  acts_as_paranoid

  validates_presence_of :price_group_id

  def member_type
    type.sub("PriceGroupMember", "")
  end

end
