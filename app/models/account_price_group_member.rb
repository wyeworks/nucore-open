# frozen_string_literal: true

class AccountPriceGroupMember < PriceGroupMember
  belongs_to :account

  validates :account_id, presence: true
  validates :account_id, uniqueness: { scope: [:price_group_id] }

  def to_log_s
    "#{account} / #{price_group_with_deleted}"
  end
end
