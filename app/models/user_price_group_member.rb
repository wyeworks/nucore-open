# frozen_string_literal: true

class UserPriceGroupMember < PriceGroupMember

  belongs_to :user

  validates_presence_of :user_id
  validates_uniqueness_of :user_id, scope: [:price_group_id]

  def to_log_s
    "#{user} / #{price_group_with_deleted}"
  end

end
