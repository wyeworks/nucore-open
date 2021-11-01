# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChartStringReassignmentForm do
  let(:account_owner) { create(:user) }
  let(:accounts) { create_list(:setup_account, users.count, owner: account_owner) }
  let(:order_details) do
    orders.map { |order| create(:order_detail, order: order, product: product) }
  end
  let(:orders) { create_list(:purchased_order, users.count, product: product) }
  let(:product) { create(:setup_item) }
  let(:users) { create_list(:user, 9) }

  describe "#available_accounts" do
    def grant_account_to_user(account, user)
      AccountUser.grant(user, AccountUser::ACCOUNT_PURCHASER, account, by: account_owner)
    end

    def grant_accounts_to_user(accounts, user)
      accounts.each { |account| grant_account_to_user(account, user) }
    end

    def random_items(list, count)
      list.shuffle.slice(0, count)
    end

    def random_item(list)
      list[rand(list.length)]
    end

    context "with a single User" do
      subject(:form) { ChartStringReassignmentForm.new([order_detail]) }
      let(:order) { order_detail.order }
      let(:order_detail) { order_details.first }
      let(:user) { users.first }

      before :each do
        order.update_attribute(:user_id, user.id)
        order_detail.update_attribute(:account_id, accounts.first.id)
        grant_accounts_to_user(accounts, user)
      end

      it "has available accounts" do
        expect(form.available_accounts.count).to eq accounts.count
      end

      it "determines available accounts" do
        expect(form.available_accounts).to match_array(user.accounts)
      end
    end

    context "with multiple Users" do
      subject(:form) { ChartStringReassignmentForm.new(order_details) }

      context "Users have all accounts in common" do
        before :each do
          users.each_with_index do |user, index|
            grant_accounts_to_user(accounts, user)

            order_details[index].update(
              account_id: random_item(accounts).id,
              order_id: orders[index].id,
            )

            orders[index].update(
              account_id: order_details[index].account_id,
              user_id: user.id,
            )
          end
        end

        it "determines available_accounts" do
          expect(form.available_accounts).to eq(accounts)
        end
      end

      context "Users have some accounts in common" do
        let(:common_accounts) { [accounts.first, accounts.last] }
        let!(:sorted_user_accounts) do
          all_user_accounts = Set.new

          users.each do |user|
            user_accounts = (common_accounts + random_items(accounts, 4)).uniq
            grant_accounts_to_user(user_accounts, user)
            all_user_accounts += user_accounts
          end

          order_details.each_with_index do |order_detail, index|
            order_detail.update_attribute(:account_id, random_item(accounts).id)
            order_detail.order.update_attribute(:user_id, users[index].id)
          end

          all_user_accounts.sort_by(&:description)
        end

        it "determines available_accounts" do
          expect(form.available_accounts).to eq sorted_user_accounts
        end
      end

      context "Users have no accounts in common" do
        let(:sorted_user_accounts) { accounts.sort_by(&:description) }

        before :each do
          accounts.each_with_index do |account, index|
            grant_account_to_user(account, users[index])
          end

          order_details.each_with_index do |order_detail, index|
            order_detail.update_attribute(:account_id, accounts[index].id)
            order_detail.order.update_attribute(:user_id, users[index].id)
          end
        end

        it "determines available_accounts" do
          expect(form.available_accounts).to eq sorted_user_accounts
        end
      end
    end
  end
end
