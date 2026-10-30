# frozen_string_literal: true

module NotificationsHelper
  def create_merge_notification_subject
    @facility ||= FactoryBot.create(:facility)
    @facility_account ||= FactoryBot.create(:facility_account, facility: @facility)
    @user ||= FactoryBot.create(:user)
    @item ||= FactoryBot.create(:item, facility: @facility, facility_account: @facility_account)

    place_product_order @user, @facility, @item
    clone = @order.dup
    assert clone.save
    @order.update_attribute :merge_with_order_id, clone.id
    @order_detail.reload
  end
end
