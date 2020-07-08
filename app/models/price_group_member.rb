# frozen_string_literal: true

class PriceGroupMember < ApplicationRecord

  belongs_to :price_group

  acts_as_paranoid

  validates_presence_of :price_group_id

  def to_log_s
    "#{user} / #{price_group}"
  end

end
