# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessageSummarizer, "with secure room problem occupancies" do
  subject(:summarizer) { MessageSummarizer.new(controller) }

  let(:controller) { FacilitiesController.new }
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price, facility:) }
  let(:account) { create(:setup_account) }
  let(:user) { create(:user) }

  before do
    create(:account_price_group_member, account:, price_group: PriceGroup.base)
    create(
      :occupancy,
      :problem_with_order_detail,
      secure_room:,
      user: account.owner_user,
      account:,
    )

    allow(controller).to receive_messages(
      admin_tab?: true,
      current_facility: facility,
      current_user: user,
    )

    summarizer.summaries.each do |summary|
      allow(summary).to receive(:path).and_return("/stub")
    end
  end

  describe "with granular permissions", feature_setting: { granular_permissions: true } do
    before do
      create(:facility_user_permission, user:, facility:, **permission_attrs)
    end

    context "with order_management" do
      let(:permission_attrs) { { read_access: true, order_management: true } }

      it "surfaces a single Problem Occupancies message" do
        expect(summarizer).to be_messages
        expect(summarizer.count).to eq(1)
        expect(summarizer.first.link).to match(/\bProblem Occupancies \(1\)/)
      end
    end

    context "with product_edition only" do
      let(:permission_attrs) { { read_access: true, product_edition: true } }

      it "does not surface the Problem Occupancies message" do
        expect(summarizer).not_to be_messages
      end
    end
  end
end
