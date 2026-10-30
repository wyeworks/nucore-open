# frozen_string_literal: true

class UserPriceGroupMember < PriceGroupMember
  belongs_to :user

  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: [:price_group_id] }

  def to_log_s
    "#{user} / #{price_group_with_deleted}"
  end
end
