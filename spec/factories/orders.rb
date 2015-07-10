FactoryGirl.define do
  factory :order do
    account nil
  end

  # Must define product or facility
  factory :setup_order, :class => Order do
    transient do
      product { nil }
    end
    facility { product.facility }
    association :account, :factory => :setup_account
    user { account.owner.user }
    created_by { account.owner.user.id }

    after(:create) do |order, evaluator|
      create(:account_price_group_member, account: order.account, price_group: evaluator.product.facility.price_groups.last)
      FactoryGirl.create(:user_price_group_member, :user => evaluator.user, :price_group => evaluator.product.facility.price_groups.last)
      order.add(evaluator.product)
    end

    factory :purchased_order do
      after(:create) do |order|
        order.stub(:cart_valid?).and_return(true) #so we don't have to worry about defining price groups, etc
        order.validate_order!
        order.purchase!
      end
    end
  end
end
