# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementRow do
  # TODO: reduce this elaborate setup!
  let(:account) { create(:nufs_account, account_users_attributes: account_users_attributes_hash(user:)) }
  let(:facility) { create(:setup_facility) }
  let(:order) { user.orders.create(FactoryBot.attributes_for(:order, facility_id: facility.id, account_id: account.id, created_by: user.id)) }
  let(:order_detail) { order.order_details.create(FactoryBot.attributes_for(:order_detail).update(product_id: service.id, account_id: account.id)) }
  let(:service) { create(:service, facility:) }
  let(:statement) { create(:statement, facility:, created_by: user.id, account:) }
  let(:user) { create(:user) }

  it "should create without error" do
    expect { StatementRow.create!(statement:, order_detail:) }
      .to_not raise_error
  end

  it { is_expected.to validate_presence_of :order_detail_id }
  it { is_expected.to validate_presence_of :statement_id }
end
