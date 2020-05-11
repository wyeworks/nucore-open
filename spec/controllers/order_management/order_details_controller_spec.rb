# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe OrderManagement::OrderDetailsController do
  def reservation_params(reserve_start_at, actual_start_at = nil)
    params = {
      reserve_start_date: I18n.l(reserve_start_at.to_date, format: :usa),
      reserve_start_hour: reserve_start_at.strftime("%l"),
      reserve_start_min: reserve_start_at.strftime("%M"),
      reserve_start_meridian: reserve_start_at.strftime("%p"),
    }

    params.merge!(
      actual_start_date: I18n.l(actual_start_at.to_date, format: :usa),
      actual_start_hour: actual_start_at.strftime("%l"),
      actual_start_min: actual_start_at.strftime("%M"),
      actual_start_meridian: actual_start_at.strftime("%p"),
    ) if actual_start_at

    params
  end

  before(:all) { create_users }
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:item) { FactoryBot.create(:setup_item, facility: facility) }
  let(:instrument) { FactoryBot.create(:setup_instrument, facility: facility, control_mechanism: "timer") }
  let(:order_detail) { reservation.order_detail }
  let(:original_account) { create(:setup_account, owner: order_detail.user) }
  let(:price_group) { facility.price_groups.find(&:is_not_global?) }
  let(:base_price_group) { PriceGroup.base }
  let(:reservation) { create(:purchased_reservation, product: instrument) }
  let(:statement) { create(:statement, facility: facility, created_by: order_detail.user.id, account: original_account) }
  let(:new_account) do
    create(:setup_account, owner: order_detail.user).tap do |a|
      AccountPriceGroupMember.create! price_group: price_group, account: a
    end
  end

  before :each do
    @authable = facility
  end

  describe "edit" do
    let(:item_order) { FactoryBot.create(:purchased_order, product: item) }
    let(:item_order_detail) { item_order.order_details.first }

    before :each do
      @action = :edit
      @method = :get
    end

    context "authentication" do
      before :each do
        @params = { facility_id: facility.url_name, order_id: item_order.id, id: item_order_detail.id }
      end
      it_should_allow_operators_only {}
    end

    context "signed in" do
      render_views

      let(:dom) { Nokogiri::HTML(response.body) }

      before :each do
        sign_in @admin
        @params = { facility_id: facility.url_name, order_id: item_order.id, id: item_order_detail.id }
      end

      context "new order" do
        before :each do
          do_request
        end

        it "is success" do
          expect(response).to be_successful
        end

        it "has new as a status" do
          expect(assigns(:order_statuses)).to include(OrderStatus.new_status)
        end

        it "does not have a price policy" do
          expect(assigns(:order_detail).price_policy).to be_blank
        end

        it "has estimated fields disabled" do
          cost = dom.css("#order_detail_estimated_cost").first
          expect(cost).to be_has_attribute("disabled")
          expect(cost["value"]).to_not be_blank

          expect(dom.css("#order_detail_estimated_subsidy").first).to be_has_attribute("disabled")
          expect(dom.css("#order_detail_estimated_total").first).to be_has_attribute("disabled")
        end

        it "has assigned user enabled" do
          expect(dom.css("#order_detail_assigned_user_id").first).to_not be_has_attribute("disabled")
        end
      end

      context "completed order" do
        before :each do
          item_order_detail.change_status!(OrderStatus.complete)
        end

        context "with a price policy" do
          context "with a subsidy" do
            before :each do
              item_order_detail.price_policy.update_attributes(unit_subsidy: 1)
              item_order_detail.assign_price_policy
              item_order_detail.save!
              do_request
            end

            it "has actual fields" do
              cost = dom.css("#order_detail_actual_cost").first
              expect(cost).to be_present
              expect(cost["value"]).to_not be_blank
            end

            it "has the subsidy field enabled" do
              subsidy = dom.css("#order_detail_actual_subsidy").first
              expect(subsidy).to be_present
              expect(subsidy["value"]).to_not be_blank
              expect(subsidy).to_not be_has_attribute("disabled")
            end
          end

          context "without a subsidy" do
            before :each do
              item_order_detail.price_policy.update_attributes(unit_subsidy: 0)
              item_order_detail.assign_price_policy
              item_order_detail.save!
              do_request
            end

            it "has the subsidy field disabled" do
              subsidy = dom.css("#order_detail_actual_subsidy").first
              expect(subsidy).to be_has_attribute("disabled")
            end
          end
        end

        context "without a price policy" do
          before :each do
            item.price_policies.delete_all
            item_order_detail.assign_estimated_price
            item_order_detail.assign_price_policy
            item_order_detail.save!
            expect(item_order_detail.price_policy).to be_blank
            do_request
          end

          it "has a warning" do
            expect(dom.css(".alert")).to be_present
          end

          it "has estimated fields disabled" do
            cost = dom.css("#order_detail_estimated_cost").first
            expect(cost).to be_has_attribute("disabled")
            expect(cost["value"]).to be_blank
          end
        end
      end

      context "order in open journal" do
        let(:journal) { FactoryBot.create(:journal, facility: facility) }
        before :each do
          item_order_detail.change_status!(OrderStatus.complete)
          item_order_detail.update_attributes(reviewed_at: 1.day.ago)
          journal.create_journal_rows! [item_order_detail]
          item_order_detail.reload
          expect(item_order_detail.journal).to be_present

          do_request
        end

        it "has an alert" do
          expect(dom.css(".alert")).to be_present
        end
      end
    end
  end

  shared_examples_for "it was removed from its statement" do
    it "should no longer be statemented" do
      expect { do_request }.to change { order_detail.reload.statement }
        .from(statement).to(nil)
    end

    it "should no longer have a statement date" do
      original_statement_date = order_detail.statement_date
      expect { do_request }.to change { order_detail.reload.statement_date }
        .from(original_statement_date).to(nil)
    end
  end

  describe "PUT #update" do
    before do
      @action = :update
      @method = :put
      @params = {
        facility_id: facility.url_name,
        order_id: order_detail.order_id,
        id: order_detail.id,
      }
    end

    describe "for a reservation" do
      it_should_allow_operators_only(:redirect) {}

      context "when signed in as an administrator" do
        before { sign_in @admin }

        describe "updating reservation times" do
          before do
            instrument.price_policies.first.update_attributes(
              usage_rate: 120,
              usage_subsidy: 60,
              charge_for: InstrumentPricePolicy::CHARGE_FOR[:usage],
            )
          end

          context "reserve times on incomplete order" do
            let(:new_reserve_start) { reservation.reserve_start_at + 1.hour }

            before do
              instrument.update_attributes(min_reserve_mins: 1)
              @params[:order_detail] = {
                reservation: reservation_params(new_reserve_start).merge(duration_mins: 30),
              }
            end

            context "does not conflict with another reservation" do
              before { do_request }

              it "updates the reservation", :aggregate_failures do
                expect(reservation.reload.reserve_start_at)
                  .to eq(new_reserve_start)
                expect(reservation.reserve_end_at)
                  .to eq(new_reserve_start + 30.minutes)
              end

              it "updates the estimated cost", :aggregate_failures do
                expect(order_detail.reload.estimated_cost).to eq(60)
                expect(order_detail.estimated_subsidy).to eq(30)
              end
            end

            context "it conflicts with another reservation" do
              before do
                FactoryBot.create(:purchased_reservation,
                                  reserve_start_at: new_reserve_start,
                                  product: instrument)
                do_request
              end

              it "does not save the reservation" do
                expect(assigns(:order_detail).reservation).to be_changed
              end

              it "renders an error", :aggregate_failures do
                expect(flash[:error]).to be_present
                expect(assigns(:order_detail).errors.full_messages).to include("The reservation conflicts with another reservation.")
                expect(response).to render_template(:edit)
                expect(response.code).to eq("406")
              end
            end
          end

          describe "trying to set zero minutes" do
            before do
              @params[:order_detail] = {
                reservation: reservation_params(order_detail.reservation.reserve_start_at).merge(duration_mins: 0),
              }
              do_request
            end

            it "does not save the reservation" do
              expect(assigns(:order_detail).reservation).to be_changed
            end

            it "renders an error", :aggregate_failures do
              expect(flash[:error]).to be_present
              expect(assigns(:order_detail).errors.full_messages).to include("Duration must be at least 1 minute")
              expect(response).to render_template(:edit)
              expect(response.code).to eq("406")
            end
          end

          context "and it is a restricted instrument" do
            before do
              instrument.update_attributes(requires_approval: true, min_reserve_mins: 10)
              @params[:order_detail] = {
                reservation: reservation_params(reservation.reserve_start_at).merge(duration_mins: 30),
              }
              do_request
            end

            it "allows editing", :aggregate_failures do
              expect(assigns(:order_detail)).to_not be_changed
              expect(assigns(:order_detail).reservation).to_not be_changed
              expect(flash[:error]).to be_blank
            end
          end
        end

        describe "canceling an order" do
          before do
            instrument.update_attributes!(min_cancel_hours: 72)
            instrument.price_policies.first.update_attributes(
              cancellation_cost: 100,
              charge_for: InstrumentPricePolicy::CHARGE_FOR[:usage],
            )

            @params[:order_detail] = {
              order_status_id: OrderStatus.canceled.id.to_s,
            }
          end

          context "with cancellation fee" do
            before do
              @params[:with_cancel_fee] = "1"
              do_request
            end

            it "cancels the order detail and reservation" do
              expect(assigns(:order_detail).order_status.name).to eq("Complete")
              expect(assigns(:order_detail).reservation).to be_canceled
            end

            it "assigns the cancellation fee" do
              expect(assigns(:order_detail).actual_total).to eq(100)
            end
          end

          context "with a cancellation fee and was completed" do
            before :each do
              reservation.update_attributes(reserve_start_at: 24.hours.ago,
                                            actual_start_at: nil,
                                            actual_end_at: nil)

              travel_and_return(7.days) do
                order_detail.change_status!(OrderStatus.complete)
              end

              @params[:with_cancel_fee] = "1"
              do_request
            end

            it "cancels the order detail and reservation", :aggregate_failures do
              expect(assigns(:order_detail)).to be_complete
              expect(assigns(:order_detail).reservation).to be_canceled
            end

            it "assigns the cancellation fee" do
              expect(assigns(:order_detail).actual_total).to eq(100)
            end

            it "assigns a price policy" do
              expect(assigns(:order_detail).price_policy).to be_present
            end
          end

          context "without cancellation fee" do
            before { do_request }

            it "cancels the order detail and reservation", :aggregate_failures do
              expect(assigns(:order_detail)).to be_canceled
              expect(assigns(:order_detail).reservation).to be_canceled
            end

            it "does not assign the cancellation fee" do
              expect(assigns(:order_detail).actual_total.to_i).to eq(0)
            end
          end
        end

        describe "when there are auto-scaled accessories" do
          let!(:accessory) { create(:time_based_accessory, parent: instrument, facility: facility, scaling_type: "auto") }

          before do
            allow_any_instance_of(OrderDetail).to receive(:updated_children).and_return([build_stubbed(:order_detail)])
            @params[:order_detail] = {
              reservation: { actual_duration_mins: 45 },
            }
          end

          it "sets the flash" do
            do_request
            expect(flash[:notice]).to include "Auto-scaled accessories"
          end
        end

        context "across fiscal year/price policy expiration lines" do
          let(:first_price_policy) { order_detail.product.price_policies.first }
          let(:reservation) { FactoryBot.create(:completed_reservation, product: instrument) }
          let(:order_detail) { reservation.order_detail }

          before do
            first_price_policy
              .update_attributes!(start_date: order_detail.fulfilled_at - 1.hour, expire_date: 1.hour.ago)
          end

          context "changing account" do
            before do
              AccountPriceGroupMember.create! price_group: base_price_group, account: original_account
              AccountPriceGroupMember.create! price_group: base_price_group, account: new_account
              AccountPriceGroupMember.create! price_group: price_group, account: original_account
              order_detail.account = original_account
              order_detail.save
              order_detail.update_attributes(statement_id: statement.id, price_policy_id: PricePolicy.first.id)

              @params[:order_detail] = { account_id: new_account.id }
            end

            it "has no errors" do
              do_request
              expect(assigns(:order_detail).errors).to be_empty
            end

            it "updates the account" do
              expect { do_request }.to change { order_detail.reload.account }
                .from(original_account).to(new_account)
            end

            it "still has a price policy" do
              expect { do_request }
                .to_not change { order_detail.reload.price_policy.present? }
            end

            it_behaves_like "it was removed from its statement"
          end

          context "canceling" do
            before do
              AccountPriceGroupMember.create! price_group: base_price_group, account: original_account
              AccountPriceGroupMember.create! price_group: base_price_group, account: new_account
              AccountPriceGroupMember.create! price_group: price_group, account: original_account
              order_detail.account = original_account
              order_detail.save
              order_detail.update_attributes(statement_id: statement.id, price_policy_id: PricePolicy.first.id)

              @params[:order_detail] = {
                order_status_id: OrderStatus.canceled.id.to_s,
              }
            end

            context "with a cancellation fee" do
              before do
                @params[:with_cancel_fee] = "1"
                instrument.update_attributes!(min_cancel_hours: 72)
                instrument.price_policies.first.update_attributes(
                  cancellation_cost: 100,
                  charge_for: InstrumentPricePolicy::CHARGE_FOR[:usage],
                )
              end

              it "cancels" do
                do_request
                expect(order_detail.reload).to be_complete
              end

              it "still has a price policy" do
                expect { do_request }
                  .to_not change { order_detail.reload.price_policy.present? }
              end

              it "is priced according to the price policy" do
                original_actual_total = order_detail.actual_total
                expect { do_request }
                  .to change { order_detail.reload.actual_total }
                  .from(original_actual_total).to(100)
              end

              it "remains on its statement" do
                expect { do_request }
                  .to_not change { order_detail.reload.statement }
              end
            end

            context "without a cancellation fee" do
              it "cancels" do
                do_request
                expect(order_detail.reload).to be_canceled
              end

              it "longer has a price policy" do
                original_price_policy = order_detail.price_policy
                expect { do_request }
                  .to change { order_detail.reload.price_policy }
                  .from(original_price_policy).to(nil)
              end

              it "no longer has a price" do
                do_request
                expect(order_detail.reload.actual_total).to be_nil
              end

              it_behaves_like "it was removed from its statement"
            end
          end
        end
      end
    end

    describe "for a purchased item" do
      let(:order) { FactoryBot.create(:purchased_order, product: item) }
      let(:order_detail) { order.order_details.first }

      it_should_allow_operators_only(:redirect) {}

      context "when signed in as an administrator" do
        before { sign_in @admin }

        describe "updating pricing" do
          before { order_detail.change_status!(OrderStatus.complete) }

          describe "price change reason" do
            # the expected price (calculated from the price policy) is 1

            context "with reason required off", feature_setting: { price_change_reason_required: false } do
              it "does not require a reason when the price is changed" do
                @params[:order_detail] = {
                  actual_cost: "10",
                  actual_subsidy: order_detail.actual_subsidy,
                }
                do_request

                expect(assigns[:order_detail].errors).not_to include :price_change_reason
              end
            end

            context "with reason required on", feature_setting: { price_change_reason_required: true } do
              it "requires a reason when the price is changed from the expected price" do
                @params[:order_detail] = {
                  actual_cost: "10",
                  actual_subsidy: order_detail.actual_subsidy,
                  price_change_reason: "",
                }
                do_request

                expect(assigns[:order_detail].errors).to be_added(:price_change_reason, :blank)
                expect(assigns[:order_detail].errors).not_to be_added(:price_change_reason, :too_short, count: 10)
              end

              it "requires the reason to be at least 10 characters long" do
                @params[:order_detail] = {
                  actual_cost: "10",
                  price_change_reason: "123456789",
                }
                do_request

                expect(assigns[:order_detail].errors).to be_added(:price_change_reason, :too_short, count: 10)
              end

              it "does not require a reason if the price matches the expected price" do
                @params[:order_detail] = {
                  actual_cost: "1",
                  actual_subsidy: order_detail.actual_subsidy,
                }
                do_request

                expect(assigns[:order_detail].errors).not_to include :price_change_reason
              end
            end

          end

          describe "tracking price updates" do
            # the expected price (calculated from the price policy) is 1

            context "when the price has not been manually changed (at expected price)" do
              context "when changing price change reason" do
                it "nils price_changed_by_user" do
                  @params[:order_detail] = {
                    actual_cost: order_detail.actual_cost,
                    actual_subsidy: order_detail.actual_subsidy,
                    price_change_reason: "this is a reason",
                  }
                  do_request

                  expect(order_detail.reload.price_changed_by_user).to be_nil
                end
              end

              context "when changing price manually" do
                it "sets price_changed_by_user" do
                  @params[:order_detail] = {
                    actual_cost: "10",
                    actual_subsidy: order_detail.actual_subsidy,
                    price_change_reason: "this is a reason",
                  }
                  do_request

                  expect(order_detail.reload.price_changed_by_user).to eq @admin
                end

                it "log the price change" do
                  @params[:order_detail] = {
                    actual_cost: "10",
                    actual_subsidy: order_detail.actual_subsidy,
                    price_change_reason: "this is a reason",
                  }
                  do_request

                  log_event = LogEvent.find_by(loggable: order_detail, event_type: :price_change)
                  expect(log_event).to be_present
                end

                it "doesn't log the price change when there is an error" do
                  @params[:order_detail] = {
                    actual_cost: "-10",
                    actual_subsidy: order_detail.actual_subsidy,
                    price_change_reason: "this is a reason",
                  }
                  do_request

                  log_event = LogEvent.find_by(loggable: order_detail, event_type: :price_change)
                  expect(log_event).not_to be_present
                end
              end

              context "when changing subsidy manually" do
                it "sets price_changed_by_user" do
                  @params[:order_detail] = {
                    actual_cost: order_detail.actual_cost,
                    actual_subsidy: "0.5",
                    price_change_reason: "this is a reason",
                  }
                  do_request

                  expect(order_detail.reload.price_changed_by_user).to eq @admin
                end
              end
            end

            context "when price has been changed once (at manually set price)" do
              before do
                order_detail.update_attributes(actual_cost: "10", price_change_reason: "i am a reason", price_changed_by_user: create(:user))
              end

              context "when changing the note" do
                it "does not change price_changed_by_user" do
                  @params[:order_detail] = {
                    actual_cost: order_detail.actual_cost,
                    actual_subsidy: order_detail.actual_subsidy,
                    note: "i am a note",
                  }

                  expect { do_request }.not_to change { order_detail.reload.price_changed_by_user }
                end
              end

              context "when changing price change reason" do
                it "updates price_changed_by_user" do
                  @params[:order_detail] = {
                    actual_cost: order_detail.actual_cost,
                    actual_subsidy: order_detail.actual_subsidy,
                    price_change_reason: "i am a new reason",
                  }
                  expect { do_request }.to change { order_detail.reload.price_changed_by_user }.to @admin
                end
              end

              context "when changing price manually" do
                it "updates price_changed_by_user" do
                  @params[:order_detail] = {
                    actual_cost: "15",
                    actual_subsidy: order_detail.actual_subsidy,
                  }

                  expect { do_request }.to change { order_detail.reload.price_changed_by_user }.to @admin
                end
              end

              context "when changing subsidy manually" do
                it "updates price_changed_by_user" do
                  @params[:order_detail] = {
                    actual_cost: order_detail.actual_cost,
                    actual_subsidy: "3",
                  }

                  expect { do_request }.to change { order_detail.reload.price_changed_by_user }.to @admin
                end
              end

              context "when changing price back to 'expected' price" do
                it "updates price_changed_by_user" do
                  @params[:order_detail] = {
                    actual_cost: "1", # this is the expected price (calculated from the price policy)
                    actual_subsidy: order_detail.actual_subsidy,
                  }

                  expect { do_request }.to change { order_detail.reload.price_changed_by_user }.to nil
                end
              end
            end

          end

          it "updates the price manually" do
            @params[:order_detail] = {
              actual_cost: "20.00",
              actual_subsidy: "4.00",
              price_change_reason: "i am a reason",
            }
            do_request
            expect(order_detail.reload.actual_total).to eq(16.00)
          end

          it "updates the price while changing accounts" do
            @params[:order_detail] = {
              actual_cost: "20.00",
              actual_subsidy: "4.00",
              account_id: new_account.id,
              price_change_reason: "changing the account",
            }
            do_request
            expect(order_detail.reload.actual_total).to eq(16.00)
          end

          it "returns an error when trying to set subsidy more than cost" do
            @params[:order_detail] = {
              actual_cost: "10.00",
              actual_subsidy: "11.00",
            }
            do_request
            expect(assigns(:order_detail).errors).to include(:actual_total)
          end
        end

        describe "when the price policy would change" do
          let!(:previous_price_policy) do
            FactoryBot.create(:item_price_policy,
                              product: item,
                              price_group: price_group,
                              unit_cost: 19,
                              start_date: 30.days.ago,
                              expire_date: 28.days.ago,
                             )
          end
          before { order_detail.backdate_to_complete!(29.days.ago) }

          it "uses the fulfillment price policy rather than now's", :aggregate_failures do
            @params[:order_detail] = {
              account_id: new_account.id,
            }
            do_request
            expect(order_detail.reload.price_policy).to eq(previous_price_policy)
            expect(order_detail.actual_total).to eq(19)
          end
        end

        describe "changing quantity" do
          before do
            order_detail.backdate_to_complete!(Time.current)
            @params[:order_detail] = { quantity: 2 }
          end

          it "updates the quantity" do
            expect { do_request }
              .to change { order_detail.reload.quantity }.to(2)
          end

          it "updates the price while changing quantity" do
            @params[:order_detail] = {
              actual_cost: "20.00",
              actual_subsidy: "4.00",
              quantity: 36,
              price_change_reason: "i am a reason",
            }
            do_request
            expect(order_detail.reload.actual_total).to eq(16.00)
          end
        end

        describe "when adding a note" do
          it "updates the note" do
            @params[:order_detail] = { note: "A note" }
            do_request
            expect(order_detail.reload.note).to eq("A note")
          end
        end

        describe "when adding a reference id" do
          it "updates the reference_id" do
            @params[:order_detail] = { reference_id: "Ref 123" }
            do_request
            expect(order_detail.reload.reference_id).to eq("Ref 123")
          end
        end

        describe "assigning to a user" do
          let(:staff_user) { FactoryBot.create(:user, :staff, facility: facility) }

          before do
            @params[:order_detail] = { assigned_user_id: staff_user.id.to_s }
          end

          it "updates the assigned user" do
            expect { do_request }
              .to change { order_detail.reload.assigned_user }
              .to(staff_user)
          end

          context "when assignment notifications are on", feature_setting: { order_assignment_notifications: true } do
            it "sends a notification to the assigned user" do
              expect { do_request }
                .to change(ActionMailer::Base.deliveries, :count).by(1)
            end
          end

          context "when assignment notifications are off", feature_setting: { order_assignment_notifications: false } do
            it "sends no notifications" do
              expect { do_request }
                .not_to change(ActionMailer::Base.deliveries, :count)
            end
          end
        end

        describe "resolving dispute" do
          let(:dispute_by) { create(:user, :facility_director, facility: facility) }

          before do
            order_detail.change_status!(OrderStatus.complete)
            order_detail.update_attributes!(
              reviewed_at: Time.zone.now,
              dispute_at: Time.zone.now,
              dispute_reason: "silly reason",
              dispute_by: dispute_by,
            )
            @params[:order_detail] = {}
          end

          context "when resolve_dispute is checked" do
            before do
              @params[:order_detail].merge!(
                resolve_dispute: "1",
                dispute_resolved_reason: dispute_resolved_reason,
              )
            end

            context "with a resolved dispute reason" do
              let(:dispute_resolved_reason) { "dispute resolved" }

              it "resolves the dispute", :aggregate_failures do
                do_request

                expect(assigns(:order_detail).dispute_resolved_at).to be_present
                expect(order_detail.reload.dispute_resolved_at).to be_present
                expect(order_detail.dispute_resolved_reason)
                  .to eq(dispute_resolved_reason)
              end

              it "triggers an email to the dispute by and the account owner" do
                expect { do_request }.to change { ActionMailer::Base.deliveries.map(&:to) }
                  .by(containing_exactly(
                        [dispute_by.email],
                        [order_detail.account.owner_user.email],
                      ))
              end

              context "the dispute by is the same as the account owner" do
                let(:dispute_by) { order_detail.account.owner_user }

                it "only triggers one email" do
                  expect { do_request }.to change(ActionMailer::Base.deliveries, :count).by(1)
                end
              end
            end

            context "without a resolved dispute reason" do
              let(:dispute_resolved_reason) { "" }

              it "renders the edit template with errors", :aggregate_failures do
                do_request
                expect(response).to render_template(:edit)
                expect(assigns(:order_detail).errors)
                  .to include(:dispute_resolved_reason)
                expect(assigns(:order_detail).dispute_resolved_at).to be_nil
              end

              it "does not trigger an email" do
                expect { do_request }.not_to change(ActionMailer::Base.deliveries, :count)
              end
            end
          end

          context "when resolve_dispute is unchecked" do
            before do
              @params[:order_detail][:resolve_dispute] = "0"
            end

            it "does not resolve the dispute", :aggregate_failures do
              do_request
              expect(assigns(:order_detail).dispute_resolved_at).to be_nil
              expect(order_detail.reload.dispute_resolved_at).to be_nil
            end

            it "does not trigger an email" do
              expect { do_request }.not_to change(ActionMailer::Base.deliveries, :count)
            end
          end
        end

        describe "marking as complete", :timecop_freeze do
          describe "without a fulfillment date" do
            before do
              @params[:order_detail] = {
                order_status_id: OrderStatus.complete.id.to_s,
              }
              do_request
            end

            it "marks as now" do
              expect(order_detail.reload.fulfilled_at).to match_date(Time.current)
            end
          end

          describe "with a fulfillment date" do
            before do
              @params[:order_detail] = {
                order_status_id: OrderStatus.complete.id.to_s,
                fulfilled_at: I18n.l(fulfilled_at.to_date, format: :usa),
              }
              do_request
            end

            describe "of yesterday" do
              let(:fulfilled_at) { 1.day.ago }

              it "sets the date to noon of that day" do
                expect(order_detail.reload.fulfilled_at).to eq(1.day.ago.to_date + 12.hours)
              end
            end

            describe "of tomorrow" do
              let(:fulfilled_at) { 1.day.from_now }

              it "does not persist and errors" do
                expect(assigns(:order_detail)).to be_changed
                expect(assigns(:order_detail).errors).to include(:fulfilled_at)
              end
            end

            describe "of before the previous fiscal year" do
              let(:fulfilled_at) { 3.years.ago }

              it "does not persist and errors" do
                expect(assigns(:order_detail)).to be_changed
                expect(assigns(:order_detail).errors).to include(:fulfilled_at)
              end
            end
          end
        end

        describe "reconciling", :time_travel do
          before do
            order_detail.change_status!(OrderStatus.complete)
            order_detail.update_attributes(reviewed_at: 1.day.ago)
            @params[:order_detail] = {
              order_status_id: OrderStatus.reconciled.id,
            }
          end

          it "make the order reconciled", :aggregate_failures do
            expect { do_request }
              .to change { order_detail.reload.state }
              .to("reconciled")
            expect(order_detail.order_status)
              .to eq(OrderStatus.reconciled)
          end

          it "sets reconciled_at to now" do
            expect { do_request }
              .to change { order_detail.reload.reconciled_at }
              .to(Time.current.change(usec: 0))
          end
        end
      end
    end
  end

  describe "pricing" do
    let(:reservation) { FactoryBot.create(:purchased_reservation, product: instrument) }
    let(:order_detail) { reservation.order_detail }
    let(:price_policy) { instrument.price_policies.first }

    before :each do
      @action = :pricing
      @method = :get
      @params = { facility_id: facility.url_name, order_id: order_detail.order.id, id: order_detail.id }
    end

    context "authorization" do
      it_should_allow_operators_only {}
    end

    context "signed in" do
      before :each do
        sign_in @admin
        expect(instrument.price_policies).to be_one
        price_policy.update_attributes(
          charge_for: InstrumentPricePolicy::CHARGE_FOR[:usage],
          usage_rate: 120,
          usage_subsidy: 60,
        )

        order_detail.assign_estimated_price
        order_detail.save
      end

      it "has the correct original price" do
        expect(order_detail.estimated_total).to eq(reservation.duration_mins)
      end

      context "incomplete reservation" do
        let(:new_duration) { 73 }
        let(:json_response) { JSON.parse(response.body) }
        before :each do
          @params[:order_detail] = {
            reservation: reservation_params(reservation.reserve_start_at)
                                   .merge(duration_mins: new_duration),
          }
          do_request
        end

        it "is successful" do
          expect(response).to be_successful
        end

        it "returns a new estimated price" do
          expect(json_response["estimated_cost"].to_i).to eq(new_duration * 2)
          expect(json_response["estimated_subsidy"].to_i).to eq(new_duration)
          expect(json_response["estimated_total"].to_i).to eq(new_duration)
        end

        it "does not return actual price" do
          expect(json_response["actual_cost"]).to be_blank
          expect(json_response["actual_subsidy"]).to be_blank
          expect(json_response["actual_total"]).to be_blank
        end

        it "does not actually update the order detail" do
          expect(reservation.reload.duration_mins).to eq(60)
          expect(order_detail.reload.estimated_total).to eq(60)
        end
      end

      context "completed reservation" do
        let(:new_duration) { 73 }
        let(:json_response) { JSON.parse(response.body) }

        before :each do
          reservation.update_attributes(reserve_start_at: reservation.reserve_start_at - 2.days, reserve_end_at: reservation.reserve_end_at - 2.days)
          order_detail.update_order_status! @admin, OrderStatus.complete
          @params[:order_detail] = {
            reservation: reservation_params(reservation.reserve_start_at, reservation.reserve_start_at)
                                   .merge(duration_mins: reservation.duration_mins, actual_duration_mins: new_duration),
          }
          expect(order_detail).to be_complete
        end

        context "with a valid price policy" do
          before :each do
            do_request
          end

          it "is successful" do
            expect(response).to be_successful
          end

          it "returns a new actual price" do
            expect(json_response["actual_cost"].to_i).to eq(new_duration * 2)
            expect(json_response["actual_subsidy"].to_i).to eq(new_duration)
            expect(json_response["actual_total"].to_i).to eq(new_duration)
          end

          it "does not actually update the order detail" do
            expect(reservation.reload.duration_mins).to eq(60)
            expect(order_detail.reload.estimated_total).to eq(60)
          end
        end

        context "with a price policy that expired, but was in effect when the order was fulfilled" do
          before :each do
            instrument.price_policies.update_all(start_date: 3.days.ago, expire_date: 1.day.ago)
            order_detail.update_attributes(fulfilled_at: 2.days.ago)
            order_detail.assign_price_policy
            order_detail.save!
            expect(order_detail.price_policy).to be_blank
            do_request
          end

          it "returns an actual price" do
            expect(json_response["actual_total"]).to be_present
            expect(json_response["price_group"]).to be_present
          end
        end

        context "without a valid price policy" do
          before :each do
            instrument.price_policies.delete_all
            order_detail.assign_price_policy
            order_detail.save!
            expect(order_detail.price_policy).to be_blank
            do_request
          end

          it "is successful" do
            expect(response).to be_successful
          end

          it "does not return an estimated price" do
            expect(json_response["estimated_cost"]).to be_blank
            expect(json_response["estimated_subsidy"]).to be_blank
            expect(json_response["estimated_total"]).to be_blank
          end

          it "does not return actual price" do
            expect(json_response["actual_cost"]).to be_blank
            expect(json_response["actual_subsidy"]).to be_blank
            expect(json_response["actual_total"]).to be_blank
          end

          it "does not actually update the order detail" do
            expect(reservation.reload.duration_mins).to eq(60)
            expect(order_detail.reload.estimated_total).to eq(60)
          end
        end
      end
    end
  end

  context "#remove_from_journal" do
    let(:journal) do
      create(:journal, facility: facility, updated_by: 1, reference: "xyz")
    end

    before :each do
      @method = :post
      @action = :remove_from_journal
      @params = {
        facility_id: facility.url_name,
        order_id: order_detail.order.id,
        id: order_detail.id,
      }

      order_detail.journal = journal
      create(:journal_row, journal: journal, order_detail: order_detail)
      order_detail.save!
    end

    it_should_allow_operators_only :redirect do
      expect(order_detail.reload.journal).to be_nil
      is_expected.to set_flash
      assert_redirected_to facility_order_path(facility, order_detail.order)
    end
  end
end
