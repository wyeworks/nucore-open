# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityOrderDetailsController do
  render_views

  let(:order_detail) { @order_detail }

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:setup_facility)
    @product = FactoryBot.create(:item,
                                 facility: @authable,
                                )
    @account = create_nufs_account_with_owner :director
    @order = FactoryBot.create(:order,
                               facility: @authable,
                               user: @director,
                               created_by: @director.id,
                               account: @account,
                               state: "purchased",
                              )
    @price_group = FactoryBot.create(:price_group, facility: @authable)
    @price_policy = FactoryBot.create(:item_price_policy, product: @product, price_group: @price_group)
    @order_detail = FactoryBot.create(:order_detail, order: @order, product: @product, price_policy: @price_policy, ordered_at: Time.current)
    @order_detail.set_default_status!
    @params = { facility_id: @authable.url_name, order_id: @order.id, id: @order_detail.id }
  end

  context "destroy" do
    before :each do
      @method = :delete
      @action = :destroy
    end

    it_should_allow_operators_only :redirect do
      expect(flash[:notice]).to be_present
      expect(@order_detail.reload).not_to be_frozen
      assert_redirected_to facility_order_path(@authable, @order)
    end

    context "merge order" do
      before :each do
        # @clone is the original order, @order is the merge order
        @clone = @order.dup
        assert @clone.save
        @order.update_attribute :merge_with_order_id, @clone.id
      end

      it_should_allow :director, "to destroy a detail that is part of a merge order" do
        expect { OrderDetail.find(order_detail.id) }
          .to raise_error ActiveRecord::RecordNotFound
        expect(flash[:notice]).to be_present
        assert_redirected_to facility_order_path(@authable, @clone)
      end

      context "when deleting fails" do
        let(:merge_order) { @order.dup }
        let(:journal) { FactoryBot.create(:journal) }
        let(:service) { FactoryBot.create(:setup_service, :with_order_form) }
        let(:complete_merge_order_detail) do
          FactoryBot.create(:order_detail,
                            :completed,
                            order: merge_order,
                            product: service,
                            price_policy: @price_policy,
                            ordered_at: Time.current,
                            fulfilled_at: Time.current,
                            account: @account,
                            journal: journal)
        end

        before :each do
          JournalRowBuilder.create_for_single_order_detail!(journal, complete_merge_order_detail)
          @params = { facility_id: @authable.url_name, order_id: merge_order.id, id: complete_merge_order_detail.id }
        end

        it_should_allow :director, "to see an error message when destroy fails" do
          expect(complete_merge_order_detail).to be_persisted
          expect(flash[:error]).to be_present
          assert_redirected_to facility_order_path(@authable, @clone)
        end
      end
    end
  end
end
