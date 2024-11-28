# frozen_string_literal: true

namespace :umass_corum do
  namespace :demo do
    # rake 'umass_corum:demo:voucher_statements[147]'
    desc "Generate demo voucher split account and transactions with statements"
    task :voucher_statements, [:number] => :environment do |_t, args|

      account_user = User.find_by(username: "admin@example.com") || User.first
      number = args.number.to_i
      voucher_split_account = FactoryBot.create(:voucher_split_account, owner: account_user, primary_subaccount: CreditCardAccount.first)
      facility = Facility.first
      item = Item.find_by(url_name: "example-item") || Item.first

      FactoryBot.build(:account_price_group_member, account: voucher_split_account, price_group: PriceGroup.external).save

      # Create a price rule to allow purchasing the item with the voucher split account
      ipp = ItemPricePolicy.find_or_initialize_by(product_id: item.id, price_group_id: PriceGroup.external.id) do |price_policy|
        price_policy.can_purchase = true
        price_policy.start_date = 1.day.ago
        price_policy.expire_date = SettingsHelper.fiscal_year_end - 1.day
        price_policy.unit_cost = 30
        price_policy.unit_subsidy = 0
        price_policy.note = "Notes are required"
      end
      ipp.save

      number.times do
        statement = FactoryBot.create(
          :statement,
          account: voucher_split_account,
          created_by_user: account_user,
          facility: facility
        )

        order = FactoryBot.create(
          :setup_order,
          product: item,
          account: voucher_split_account,
          quantity: 5,
          order_detail_attributes: { reviewed_at: Time.current + 5.minutes } # mark as reviewed
        )

        # Purchase the order
        order.set_order_details_ordered_at
        order.validate_order!
        order.purchase!
        order.order_details.update_all(ordered_at: Time.current)
        order.order_details.each(&:complete!)
        # Create a statement
        order_detail = order.order_details.first
        order_detail.statement_id = statement.id
        order_detail.save
      end
    end
  end
end
