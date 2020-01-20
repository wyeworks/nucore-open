# frozen_string_literal: true

RSpec.shared_examples_for PricePoliciesController do |product_type, params_modifier = nil|
  let(:facility) { @authable }
  let(:price_policy) { @price_policy }
  let(:product) { @product }

  before(:each) do
    @product_type = product_type
    @params_modifier = params_modifier
    @authable = FactoryBot.create(:setup_facility)

    # Delete the default price groups since they get in the way of testing
    UserPriceGroupMember.delete_all
    PriceGroup.delete_all

    @price_group = FactoryBot.create(:price_group, facility: facility)
    @price_group2 = FactoryBot.create(:price_group, facility: facility)
    @product = create(product_type, facility: @authable)
    @price_policy = make_price_policy(@price_group)
    expect(@price_policy).to be_valid
    @params = { :facility_id => @authable.url_name, :"#{product_type}_id" => @product.url_name }
  end

  context "index" do
    before :each do
      @method = :get
      @action = :index
      @price_policy_past = make_price_policy(@price_group, start_date: 1.year.ago, expire_date: PricePolicy.generate_expire_date(1.year.ago))
      @price_policy_future = make_price_policy(@price_group, start_date: 1.year.from_now, expire_date: PricePolicy.generate_expire_date(1.year.from_now))
    end

    it_should_allow_operators_only do |_user|
      expect(assigns[:product]).to eq(@product)
      expect(assigns[:current_price_policies]).to eq([@price_policy])
      expect(assigns[:next_price_policies_by_date].keys).to include_date @price_policy_future.start_date
      is_expected.to render_template("price_policies/index")
    end
  end

  context "#new" do
    before :each do
      @method = :get
      @action = :new
    end

    context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do

      it_should_allow_managers_only {}

      context "signed in" do
        before :each do
          maybe_grant_always_sign_in :director
        end

        it "assigns the product" do
          do_request
          expect(assigns[:product]).to eq(@product)
        end

        it "sets the date to today if there are no active policies" do
          expect(@price_policy.destroy).to eq(@price_policy)
          do_request
          expect(response.code).to eq("200")
          expect(response).to be_successful
          expect(assigns[:start_date]).not_to be_nil
          expect(assigns[:start_date]).to match_date Date.today
        end

        it "sets the date to tomorrow if there are active policies" do
          do_request
          expect(response).to be_successful
          expect(assigns[:start_date]).not_to be_nil
          expect(assigns[:start_date]).to match_date(Date.today + 1.day)
        end

        it "sets the expiration date to when the fiscal year ends" do
          do_request
          expected = PricePolicy.generate_expire_date(Date.today)
          expect(assigns[:price_policies].map(&:expire_date)).to all(be_within(1.second).of(expected))
        end

        it "has a new price policy for each group" do
          do_request
          expect(assigns[:price_policies]).to be_is_a Array
          price_groups = assigns[:price_policies].map(&:price_group)
          expect(price_groups).to contain_all PriceGroup.all
        end

        it "sets the policies in the correct order" do
          @price_group.update_attributes(display_order: 2)
          @price_group2.update_attributes(display_order: 1)
          do_request
          expect(assigns[:price_policies].map(&:price_group)).to eq([@price_group2, @price_group])
        end

        it "sets each price policy to true" do
          make_price_policy(@price_group2)
          do_request
          expect(assigns[:price_policies].size).to eq(2)
          expect(assigns[:price_policies].all?(&:can_purchase?)).to be true
        end

        it "renders the new template" do
          do_request
          expect(response).to render_template("price_policies/new")
        end

        context "old policies exist" do
          before :each do
            @price_group2_policy = make_price_policy(@price_group2, can_purchase: false, unit_cost: 13)
          end

          it "sets can_purchase based off old policy" do
            do_request
            expect(assigns[:price_policies].map(&:price_group)).to eq([@price_policy.price_group, @price_group2_policy.price_group])
            expect(assigns[:price_policies][0]).to be_can_purchase
            expect(assigns[:price_policies][1]).not_to be_can_purchase
          end

          it "sets fields based off the old policy" do
            do_request
            expect(assigns[:price_policies].map(&:price_group)).to eq([@price_policy.price_group, @price_group2_policy.price_group])
            expect(assigns[:price_policies][0].unit_cost).to eq(@price_policy.unit_cost)
            expect(assigns[:price_policies][1].unit_cost).to eq(@price_group2_policy.unit_cost)
          end

          it "leaves can_purchase as false if there isn't an existing policy for the group, but there are policies" do
            @price_group3 = FactoryBot.create(:price_group, facility: facility)

            do_request
            expect(assigns[:price_policies].size).to eq 3

            price_policy = assigns[:price_policies].find { |pp| pp.price_group_id == @price_policy.price_group_id }
            expect(price_policy).to be_can_purchase

            price_group2_policy = assigns[:price_policies].find { |pp| pp.price_group_id == @price_group2_policy.price_group_id }
            expect(price_group2_policy).to_not be_can_purchase

            price_group3_policy = assigns[:price_policies].find { |pp| pp.price_group_id == @price_group3.id }
            expect(price_group3_policy).to_not be_can_purchase
          end
          it "uses the policy with the furthest out expiration date" do
            @price_policy.update_attributes(unit_cost: 16.0)
            @price_policy2 = make_price_policy(@price_group, start_date: 1.year.from_now, expire_date: SettingsHelper.fiscal_year_end(1.year.from_now), unit_cost: 17.0)
            @price_policy3 = make_price_policy(@price_group, start_date: 1.year.ago, expire_date: SettingsHelper.fiscal_year_end(1.year.ago), unit_cost: 18.0)
            # Ensure the policy two is the one with the max expire date
            expect([@price_policy, @price_policy2, @price_policy3].max_by(&:expire_date)).to eq(@price_policy2)
            do_request
            # make sure we're not out of order
            expect(assigns[:price_policies][0].price_group).to eq(@price_group)
            # the unit cost for price_policy_2
            expect(assigns[:price_policies][0].unit_cost).to eq(17)
          end
        end
      end
    end

    context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
      it_should_allow_admin_only {}
    end

  end

  context "#edit" do
    before :each do
      @method = :get
      @action = :edit
      set_policy_date
      @params.merge!(id: @price_policy.start_date.to_s)
    end

    context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do

      it_should_allow_managers_only {}

      context "signed in" do
        before :each do
          maybe_grant_always_sign_in :director
          do_request
        end

        it "assigns start date" do
          expect(assigns[:start_date]).to eq(@price_policy.start_date)
        end

        it "returns the existing policies" do
          expect(assigns[:price_policies]).to be_include @price_policy
          expect(@price_policy).not_to be_new_record
        end

        it "returns a new policy for other groups" do
          new_price_policies = assigns[:price_policies].reject { |pp| pp.price_group == @price_group }
          expect(new_price_policies.map(&:price_group)).to contain_all(PriceGroup.all - [@price_group])
          new_price_policies.each do |pp|
            expect(pp).to be_new_record
          end
        end

        it "renders the edit template" do
          is_expected.to render_template("price_policies/edit")
        end
      end

      it "does not allow edit of assigned effective price policy" do
        @account  = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @director))
        @order    = @director.orders.create(FactoryBot.attributes_for(:order, created_by: @director.id))
        @order_detail = @order.order_details.create(FactoryBot.attributes_for(:order_detail).update(product_id: @product.id, account_id: @account.id, price_policy: @price_policy))
        UserPriceGroupMember.create!(price_group: @price_group, user: @director)
        maybe_grant_always_sign_in :director
        do_request
        expect(assigns[:start_date]).to eq(Time.zone.parse(@params[:id]))
        expect(assigns[:price_policies]).to be_empty
        is_expected.to render_template "404"
      end
    end

    context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
      it_should_allow_admin_only {}
    end

  end

  context "with policy params" do
    before :each do
      facility.price_groups.map(&:id).each do |id|
        @params.merge!(
          :"price_policy_#{id}" =>
            attributes_for(:"#{@product_type}_price_policy"),
        )
      end
    end

    context "#create" do
      before :each do
        @method = :post
        @action = :create
        @start_date = Time.zone.now + 1.year
        @expire_date = PricePolicy.generate_expire_date(@start_date)
        @params[:start_date] = @start_date.to_s
        @params[:expire_date] = @expire_date.to_s
        @params[:note] = "This is a note"

        @params_modifier.before_create @params if @params_modifier.try :respond_to?, :before_create
      end

      context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do

        it_should_allow_managers_only(:redirect) {}

        context "signed in" do
          before :each do
            maybe_grant_always_sign_in :director
          end

          it "creates the new price_groups" do
            do_request
            expect(assigns[:price_policies].map(&:price_group)).to contain_all PriceGroup.all
            assigns[:price_policies].each do |pp|
              expect(pp).not_to be_new_record
            end
          end

          it "redirects to show on success" do
            do_request
            is_expected.to redirect_to price_policy_index_path
          end

          it "creates a new price policy for a group that has no fields, but cannot purchase" do
            last_price_group = @authable.price_groups.last
            @params.delete :"price_policy_#{last_price_group.id}"
            do_request
            expect(response).to be_redirect
            price_policies_for_empty_group = assigns[:price_policies].select { |pp| pp.price_group == last_price_group }
            expect(price_policies_for_empty_group.size).to eq(1)
            expect(price_policies_for_empty_group.first).not_to be_can_purchase
          end

          it "rejects everything if expire date is before start date" do
            @params[:expire_date] = (@start_date - 2.days).to_s
            do_request
            expect(flash[:error]).not_to be_nil
            expect(response).to render_template "price_policies/new"
            assigns[:price_policies].each do |pp|
              expect(pp).to be_new_record
            end
          end

          it "does not allow same start date as assigned effective price policy" do
            @account  = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @director))
            @order    = @director.orders.create(FactoryBot.attributes_for(:order, created_by: @director.id))
            @order_detail = @order.order_details.create(FactoryBot.attributes_for(:order_detail).update(product_id: @product.id, account_id: @account.id, price_policy: @price_policy))

            @params[:start_date] = @price_policy.start_date
            do_request
            expect(assigns[:price_policies]).to be_empty
            expect(response).to redirect_to [@authable, @product, PricePolicy]
          end

          it "rejects everything if the expiration date spans into the next fiscal year" do
            @params[:expire_date] = (PricePolicy.generate_expire_date(@start_date) + 1.day).to_s
            do_request
            expect(response).to be
            expect(flash[:error]).not_to be_nil
            expect(response).to render_template "price_policies/new"
            assigns[:price_policies].each do |pp|
              expect(pp).to be_new_record
            end
          end

          it "rejects and renders an error if expires date is invalid" do
            @params[:start_date] = "5/0/2018"
            do_request
            expect(response).to render_template :new
            expect(assigns[:start_date]).to be_blank
            expect(assigns[:price_policies].first.errors).to be_added(:start_date, :blank)
            expect(assigns[:price_policies]).to all(be_new_record)
          end

          it "rejects and renders an error if expires date is invalid" do
            @params[:expire_date] = "5/0/2018"
            do_request
            expect(response).to render_template :new
            expect(assigns[:expire_date]).to be_blank
            expect(assigns[:price_policies].first.errors).to be_added(:expire_date, :blank)
            expect(assigns[:price_policies]).to all(be_new_record)
          end

          it "sets the created_by" do
            do_request
            expect(assigns[:price_policies].map(&:created_by)).to all eq(@director)
          end
        end
      end

      context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
        it_should_allow_admin_only(:redirect) {}
      end

    end

    describe "#update" do
      before(:each) do
        @method = :put
        @action = :update
        set_policy_date
        @params.merge!(
          id: price_policy.start_date.to_s,
          start_date: price_policy.start_date.to_s,
          expire_date: price_policy.expire_date.to_s,
          note: "This is a note",
        )

        if @params_modifier.respond_to?(:before_update)
          @params_modifier.before_update(@params)
        end
      end

      context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do

        it_should_allow_managers_only(:redirect) {}

        context "when signed in as a director" do
          before { maybe_grant_always_sign_in(:director) }

          it "redirects to the price policy index on success" do
            do_request
            is_expected.to redirect_to price_policy_index_path
          end

          context "when setting an expire_date param" do
            let(:new_expire_date) { price_policy.expire_date - 1.day }
            let(:updated_price_policies) do
              product.price_policies.for_date(price_policy.start_date)
            end

            before(:each) do
              @params[:expire_date] = new_expire_date.to_s
              do_request
            end

            it "updates the expiration date" do
              updated_price_policies.each do |updated_price_policy|
                expect(updated_price_policy.expire_date)
                  .to match_date(new_expire_date)
              end
            end
          end

          context "when setting a start_date param" do
            let(:new_start_date) { price_policy.start_date + 1.day }

            before(:each) do
              @params[:start_date] = new_start_date.to_s
              do_request
            end

            it "updates the start_date for all price policies" do
              assigns[:price_policies].each do |updated_price_policy|
                expect(updated_price_policy.start_date)
                  .to match_date(new_start_date)
              end
            end
          end

          context "when setting the can_purchase param to false" do
            let(:last_price_group_id) { facility.price_groups.last.id }
            let(:updated_price_policy) do
              product
                .price_policies
                .for_date(price_policy.start_date)
                .find_by(price_group_id: last_price_group_id)
            end

            before(:each) do
              @params[:"price_policy_#{last_price_group_id}"][:can_purchase] = false
              do_request
            end

            it "makes the price policy not purchaseable" do
              expect(updated_price_policy).not_to be_can_purchase
            end
          end

          context "when creating a new price group" do
            let!(:new_price_group) { FactoryBot.create(:price_group, facility: facility) }
            let(:new_price_policy) do
              product
                .price_policies
                .for_date(price_policy.start_date)
                .find_by(price_group_id: new_price_group)
            end
            let(:product_price_groups) do
              product.price_policies.map(&:price_group)
            end

            before { do_request }

            it "creates a new unpurchaseable price policy" do
              expect(product_price_groups).to be_include(new_price_group)
              expect(new_price_policy).not_to be_can_purchase
            end
          end

          shared_examples_for "it rejects expire_date changes" do
            let(:unchanged_price_policies) do
              product.price_policies.for_date(price_policy.start_date)
            end

            before(:each) do
              @params[:expire_date] = expire_date.to_s
              do_request
            end

            it { expect(flash[:error]).to include("error saving") }
            it { expect(response).to render_template("price_policies/edit") }

            it "does not update expire_dates" do
              unchanged_price_policies.each do |unchanged_price_policy|
                expect(unchanged_price_policy.expire_date)
                  .to match_date(price_policy.expire_date)
              end
            end
          end

          context "when setting the expire_date before the start_date" do
            let(:expire_date) { price_policy.start_date - 2.days }

            it_behaves_like "it rejects expire_date changes"
          end

          context "when setting the expiration_date beyond this fiscal year" do
            let(:expire_date) do
              PricePolicy.generate_expire_date(price_policy.start_date) + 1.day
            end

            it_behaves_like "it rejects expire_date changes"
          end

          it "rejects and renders an error if start date is invalid" do
            @params[:start_date] = "5/0/2018"
            do_request
            expect(response).to render_template :edit
            expect(assigns[:price_policies].map(&:start_date)).to all(be_blank)
            expect(assigns[:price_policies].first.errors).to be_added(:start_date, :blank)
          end

          it "rejects and renders an error if expires date is invalid" do
            @params[:expire_date] = "5/0/2018"
            do_request
            expect(response).to render_template :edit
            expect(assigns[:price_policies].map(&:expire_date)).to all(be_blank)
            expect(assigns[:price_policies].first.errors).to be_added(:expire_date, :blank)
          end
        end
      end

      context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
        it_should_allow_admin_only(:redirect) {}
      end

    end

    describe "#destroy" do
      before(:each) do
        @method = :delete
        @action = :destroy
        set_policy_date(1.day)
        @params[:id] = price_policy.start_date.to_s
        expect(price_policy.start_date).to be > Time.zone.now
      end

      context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do

        it_should_allow_managers_only(:redirect) {}

        context "when signed in as a director" do
          let!(:price_policies) { product.price_policies.for_date(price_policy.start_date) }

          before { maybe_grant_always_sign_in(:director) }

          context "when the price policies are destroyable" do
            before { do_request }

            it "successfully destroys them" do
              price_policies.each do |price_policy|
                expect(price_policy).to be_destroyed
              end
              expect(response).to redirect_to(price_policy_index_path)
            end
          end

          context "when a price policy is active" do
            before(:each) do
              price_policy.update_attributes(start_date: 1.day.ago, expire_date: 1.day.from_now)
              @params[:id] = price_policy.start_date.to_s
              do_request
            end

            it "will not be destroyed" do
              expect(flash[:error]).to include("cannot remove an active price policy")
              expect(response).to redirect_to(price_policy_index_path)
            end
          end

          context "when there are no price policies for the start_date" do
            before(:each) do
              @params[:id] = (price_policy.start_date + 1.day).to_s
              do_request
            end

            it { expect(response.code).to eq("404") }
          end
        end
      end

      context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
        it_should_allow_admin_only(:redirect) {}
      end

    end
  end

  private

  def price_policy_index_path
    send("facility_#{@product_type}_price_policies_path", @authable, @product)
  end

  def make_price_policy(price_group, extra_attr = {})
    create :"#{@product_type}_price_policy", extra_attr.merge(price_group: price_group, product: @product)
  end

  def set_policy_date(time_in_future = 0)
    @price_policy.start_date = Time.zone.now.beginning_of_day + time_in_future
    @price_policy.expire_date = PricePolicy.generate_expire_date(@price_policy)
    assert @price_policy.save
  end

end
