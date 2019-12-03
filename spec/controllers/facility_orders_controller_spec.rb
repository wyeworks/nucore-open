# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "order_detail_batch_update_shared_examples"

RSpec.describe FacilityOrdersController do
  let(:account) { @account }
  let(:facility) { @authable }
  let(:facility_account) { @facility_account }
  let(:product) { @product }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:facility)
    @facility_account = FactoryBot.create(:facility_account, facility: @authable)
    @product = FactoryBot.create(:item,
                                 facility_account: @facility_account,
                                 facility: @authable,
                                )
    @account = create_nufs_account_with_owner :director
    @order_detail = place_product_order(@director, @authable, @product, @account)
    @order_detail.order.update_attributes!(state: "purchased")
    @params = { facility_id: @authable.url_name }
  end

  context "#assign_price_policies_to_problem_orders" do
    let(:order_details) do
      Array.new(3) do
        order_detail = place_and_complete_item_order(@director, facility)
        order_detail.update_attribute(:price_policy_id, nil)
        order_detail
      end
    end

    let(:order_detail_ids) { order_details.map(&:id) }

    before :each do
      @method = :post
      @action = :assign_price_policies_to_problem_orders
    end

    context "when compatible price policies exist" do
      let(:price_group) { create(:price_group, facility: facility) }

      before :each do
        create(:account_price_group_member, account: account, price_group: price_group)

        order_details.each do |order_detail|
          order_detail.update_attribute(:account_id, account.id)
          order_detail.product.item_price_policies.create(attributes_for(
                                                            :item_price_policy, price_group_id: price_group.id))
        end

        do_request
      end

      it_should_allow_operators_only :redirect do
        expect(OrderDetail.where(id: order_detail_ids, problem: false).count)
          .to eq order_details.count
      end
    end

    context "when no compatible price policies exist" do
      before :each do
        ItemPricePolicy.destroy_all
        do_request
      end

      it_should_allow_operators_only :redirect do
        expect(OrderDetail.where(id: order_detail_ids, problem: true).count)
          .to eq order_details.count
      end
    end
  end

  it_behaves_like "it supports order_detail POST #batch_update"

  context "#index" do
    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_operators_only {}

    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :director
      end
      %w(order_number date product assigned_to status).each do |sort|
        it "should not blow up for sort by #{sort}" do
          @params[:sort] = sort
          do_request
          expect(response).to be_success
          expect(assigns[:order_details]).not_to be_nil
          expect(assigns[:order_details].first).not_to be_nil
        end
      end

      it "should not return reservations" do
        # setup_reservation overwrites @order_detail
        @order_detail_item = @order_detail
        @order_detail_reservation = setup_reservation(@authable, @account, @director)
        @reservation = place_reservation(@authable, @order_detail_reservation, Time.zone.now + 1.hour)

        expect(@authable.reload.order_details).to contain_all [@order_detail_item, @order_detail_reservation]
        do_request
        expect(assigns[:order_details]).to eq([@order_detail_item])
      end
    end
  end

  describe "#show" do
    before do
      maybe_grant_always_sign_in :admin
      @method = :get
      @action = :show
      @params.merge!(id: @order_detail.order.id)
    end

    describe "with an order detail with no cost assigned" do
      it "renders" do
        expect(@order_detail.actual_cost).to be_nil
        expect(@order_detail.estimated_cost).to be_nil
        expect { do_request }.not_to raise_error
      end
    end
  end

  context "#show_problems" do
    before :each do
      @method = :get
      @action = :show_problems
    end

    it_should_allow_managers_and_senior_staff_only
  end

  context "#send_receipt" do
    before :each do
      @method = :post
      @action = :send_receipt
      @params[:id] = @order.id
      request.env["HTTP_REFERRER"] = facility_order_path @authable, @order
      ActionMailer::Base.deliveries.clear
    end

    it_should_allow_operators_only :redirect, "to send a receipt" do
      expect(flash[:notice]).to include("sent successfully")
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to include("Order Receipt")
      expect(mail.from.first).to eq(Settings.email.from)
      assert_redirected_to facility_order_path(@authable, @order)
    end
  end

  describe "PUT #update" do
    let(:order) { @order }

    before do
      @method = :put
      @action = :update
      @params.merge!(id: order.id, add_to_order_form: { product_id: product.id, order_status_id: OrderStatus.new_status.id })
    end

    context "with a product_add_quantity of 0" do
      before { @params[:add_to_order_form][:quantity] = 0 }

      it_should_allow_operators_only do
        expect(flash[:error]).to include("Quantity must be greater than 0")
        expect(response).to render_template(:show)
      end
    end

    context "with a product_add_quantity of 1" do
      before do
        @params[:add_to_order_form][:quantity] = 1
        order.order_details.destroy_all
      end

      it_should_allow :director, "to add an item to existing order directly" do
        assert_no_merge_order(order, product)
        expect(order.order_details.last.created_by_user).to eq(@director)
      end

      context "when adding an instrument" do
        let(:instrument) { FactoryBot.create(:instrument, facility_account: facility_account) }
        let(:merge_order) { Order.find_by(merge_with_order_id: order.id) }
        let(:order_detail) { merge_order.order_details.last }

        before { @params[:add_to_order_form][:product_id] = instrument.id }

        it_should_allow :director, "to add an instrument to existing order via merge" do
          assert_merge_order(order, instrument)
        end

        context "when setting a note" do
          before { @params[:add_to_order_form][:note] = "This is a note" }

          it_should_allow :director, "to add an instrument to existing order via merge" do
            expect(order_detail.note).to eq("This is a note")
          end
        end

        context "when setting an order status" do
          before { @params[:add_to_order_form][:order_status_id] = order_status.id.to_s }

          context "of 'In Process'" do
            let(:order_status) { OrderStatus.in_process }

            it_should_allow :director, "to add an instrument to existing order via merge" do
              expect(order_detail.order_status).to eq(OrderStatus.in_process)
            end
          end

          context "of 'Complete'" do
            let(:order_status) { OrderStatus.complete }
            let(:director) do
              FactoryBot.create(:user, :facility_director, facility: facility)
            end

            before do
              sign_in director
              put @action, params: @params
            end

            it "errors due to an invalid transition", :aggregate_failures do
              expect(merge_order).to be_nil
              expect(flash[:error])
                .to include("may not be set initially to an order status of Complete")
            end
          end
        end
      end

      context "when adding an item" do
        let(:item) { FactoryBot.create(:item, facility_account: facility_account) }
        let(:order_detail) { order.order_details.last }

        before { @params[:add_to_order_form][:product_id] = item.id }

        it_should_allow :director, "to add an item to existing order directly" do
          assert_no_merge_order(order, item, 1)
        end

        context "when setting a note" do
          before { @params[:add_to_order_form][:note] = "This is a note" }

          it_should_allow :director, "to add an item to existing order with a note" do
            expect(order_detail.note).to eq("This is a note")
          end
        end

        context "when specifying an account" do
          let(:other_account) { create(:nufs_account, :with_account_owner, owner: order.user) }
          before { @params[:add_to_order_form][:account_id] = other_account.id }

          it_should_allow :director, "to add the item to that account" do
            expect(order.order_details.last.account).to eq(other_account)
          end

          context "and that account is suspended" do
            before { other_account.suspend }

            it_should_allow :director, "to error on that account" do
              expect(order.order_details).to be_empty
              expect(flash[:error]).to be_present
            end
          end
        end

        context "when setting the order status to 'Complete'" do
          let(:complete_status) { OrderStatus.complete }
          before { @params[:add_to_order_form][:order_status_id] = complete_status.id.to_s }

          context "and setting fulfilled_at" do
            before { @params[:add_to_order_form][:fulfilled_at] = fulfilled_at.strftime("%m/%d/%Y") }

            context "to today" do
              let(:fulfilled_at) { Date.today }

              it_should_allow :director, "to add an item to existing order with fulfilled_at set" do
                expect(order.order_details).to be_one
                expect(order_detail.order_status).to eq(complete_status)
                expect(order_detail.fulfilled_at)
                  .to eq(fulfilled_at.beginning_of_day + 12.hours)
              end
            end

            context "to a date in the future" do
              let(:fulfilled_at) { 1.day.from_now }

              it_should_allow :director, "it should not save" do
                expect(order_detail).to be_blank
                expect(flash[:error]).to include "cannot be in the future"
              end
            end

            context "to a date before the start of the previous fiscal year" do
              let(:fulfilled_at) { SettingsHelper.fiscal_year_beginning - 1.year - 1.day }

              it_should_allow :director, "it should not save" do
                expect(order_detail).to be_blank
                expect(flash[:error]).to include("fiscal year")
              end
            end

            context "to a date during this fiscal year" do
              let(:fulfilled_at) { SettingsHelper.fiscal_year_beginning + 1.day }

              it_should_allow :director, "to add an item to existing order with fulfilled_at set" do
                expect(order_detail.order_status).to eq(complete_status)
                expect(order_detail.fulfilled_at).to eq(fulfilled_at.beginning_of_day + 12.hours)
              end
            end
          end
        end

        context "when not setting an order status" do
          context "and setting fulfilled_at" do
            before { @params[:add_to_order_form][:fulfilled_at] = fulfilled_at.strftime("%m/%d/%Y") }
            let(:fulfilled_at) { Date.today }

            it_should_allow :director, "to add an item to existing order with status and fulfilled_at set to defaults" do
              expect(order_detail.order_status).to eq(item.initial_order_status)
              expect(order_detail.fulfilled_at).to be_blank
            end
          end
        end

        context "when setting an order status" do
          before { @params[:add_to_order_form][:order_status_id] = OrderStatus.in_process.id }

          it_should_allow :director, "to add an item to existing order via merge" do
            expect(order_detail.order_status).to eq(OrderStatus.in_process)
          end
        end
      end

      context "when adding a service" do
        let(:service) { FactoryBot.create(:service, facility_account: facility_account) }

        before do
          allow_any_instance_of(OrderDetail).to receive(:valid_service_meta?).and_return(false)
          allow_any_instance_of(Service).to receive(:active_survey?).and_return(active_survey?)
          allow_any_instance_of(Service).to receive(:active_template?).and_return(active_template?)
          @params[:add_to_order_form][:product_id] = service.id
        end

        shared_examples_for "directors may add via merge" do
          it_should_allow :director, "to add a service to existing order via merge" do
            assert_merge_order(order, service)
          end
        end

        context "with an active survey" do
          let(:active_survey?) { true }

          context "with an active template" do
            let(:active_template?) { true }

            it_behaves_like "directors may add via merge"
          end

          context "without an active template" do
            let(:active_template?) { false }

            it_behaves_like "directors may add via merge"
          end
        end

        context "without an active survey" do
          let(:active_survey?) { false }

          context "with an active template" do
            let(:active_template?) { true }

            it_behaves_like "directors may add via merge"
          end

          context "without an active template" do
            let(:active_template?) { false }

            it_should_allow :director, "to add a service to existing order directly" do
              assert_no_merge_order(order, service)
            end
          end
        end
      end

      context "when adding a bundle" do
        let(:bundle) do
          FactoryBot.create(:bundle, bundle_products: bundle_products, facility_account: facility_account)
        end
        let(:bundle_products) { [product, additional_product] }
        let(:additional_product) do
          FactoryBot.create(bundled_product_type, facility_account: facility_account)
        end

        before { @params[:add_to_order_form][:product_id] = bundle.id }

        context "containing an item" do
          let(:bundled_product_type) { :item }

          it_should_allow :director, "to add an item to existing order directly" do
            assert_no_merge_order(order, bundle, 2)
          end
        end

        context "containing an instrument" do
          let(:bundled_product_type) { :instrument }

          it_should_allow :director, "to add an instrument to existing order via merge" do
            assert_merge_order(order, bundle, 1, 1)
          end
        end

        context "containing a service" do
          let(:bundled_product_type) { :service }

          before do
            allow_any_instance_of(OrderDetail).to receive(:valid_service_meta?).and_return(false)
            allow_any_instance_of(Service).to receive(:active_survey?).and_return(active_survey?)
            allow_any_instance_of(Service).to receive(:active_template?).and_return(active_template?)
          end

          shared_examples_for "directors may add via merge" do
            it_should_allow :director, "to add a service to existing order via merge" do
              assert_merge_order(order, bundle, 1, 1)
            end
          end

          context "with an active survey" do
            let(:active_survey?) { true }

            context "with an active template" do
              let(:active_template?) { true }

              it_behaves_like "directors may add via merge"
            end

            context "without an active template" do
              let(:active_template?) { false }

              it_behaves_like "directors may add via merge"
            end
          end

          context "without an active survey" do
            let(:active_survey?) { false }

            context "with an active template" do
              let(:active_template?) { true }

              it_behaves_like "directors may add via merge"
            end

            context "without an active template" do
              let(:active_template?) { false }

              it_should_allow :director, "to add a service to existing order directly" do
                assert_no_merge_order(order, bundle, 2)
              end
            end
          end
        end
      end
    end

    def assert_update_success(order, product)
      if product.is_a? Bundle
        order.order_details.each do |od|
          expect(od.order_status).to eq(OrderStatus.default_order_status)
          expect(product.products).to be_include(od.product)
        end
      else
        order_detail = order.order_details[0]
        expect(order_detail.product).to eq(product)
        expect(order_detail.order_status).to eq(OrderStatus.default_order_status)
      end

      if order.to_be_merged?
        expect(flash[:error]).to include("needs your attention")
      else
        expect(flash[:notice]).to include("successfully added to this order")
      end

      assert_redirected_to facility_order_path(@authable, order.to_be_merged? ? order.merge_order : order)
    end

    def assert_no_merge_order(original_order, product, detail_count = 1)
      expect(original_order.reload.order_details.size).to eq(detail_count)
      assert_update_success original_order, product
    end

    def assert_merge_order(original_order, product, detail_count = 1, original_detail_count = 0)
      expect(original_order.reload.order_details.size).to eq(original_detail_count)
      merges = Order.where(merge_with_order_id: original_order.id)
      expect(merges.size).to eq(1)
      merge_order = merges.first
      expect(merge_order.merge_order).to eq(original_order)
      expect(merge_order.facility_id).to eq(original_order.facility_id)
      expect(merge_order.account_id).to eq(original_order.account_id)
      expect(merge_order.user_id).to eq(original_order.user_id)
      expect(merge_order.created_by).to eq(@director.id)
      expect(merge_order.order_details).to be { |od| od.ordered_at.blank? }
      expect(merge_order.order_details.size).to eq(detail_count)
      expect(MergeNotification.count).to eq(detail_count)
      assert_update_success merge_order, product
    end
  end

  context "#tab_counts" do
    before :each do
      @method = :get
      @action = :tab_counts
      @order_detail2 = FactoryBot.create(:order_detail, order: @order, product: @product)

      expect(@authable.order_details.item_and_service_orders.new_or_inprocess.size).to eq(2)

      @problem_order_details = (1..3).map do |_i|
        order_detail = place_and_complete_item_order(@staff, @authable)
        order_detail.update_attributes(price_policy_id: nil)
        order_detail
      end

      @params.merge!(tabs: %w(new_or_in_process_orders problem_order_details))
    end

    it_should_allow_operators_only {}

    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :director
      end
      it "should get only new if thats all you ask for" do
        @authable.order_details.item_and_service_orders.new_or_inprocess.to_sql
        @params[:tabs] = ["new_or_in_process_orders"]
        do_request
        expect(response).to be_success
        body = JSON.parse(response.body)
        expect(body.keys).to contain_all ["new_or_in_process_orders"]
        expect(body["new_or_in_process_orders"]).to eq(2)
      end

      it "should get everything if you ask for it" do
        do_request
        expect(response).to be_success
        body = JSON.parse(response.body)
        expect(body.keys).to contain_all %w(new_or_in_process_orders problem_order_details)
        expect(body["new_or_in_process_orders"]).to eq(2)
        expect(body["problem_order_details"]).to eq(3)
      end
    end
  end
end
