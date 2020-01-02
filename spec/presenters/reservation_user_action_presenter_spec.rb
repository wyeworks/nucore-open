# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationUserActionPresenter do
  include Rails.application.routes.url_helpers

  let(:facility) { build_stubbed(:facility) }
  let(:instrument) { build_stubbed(:instrument, facility: facility) }
  let(:order) { build_stubbed(:order, facility: facility, user: user) }
  let(:order_detail) { build_stubbed(:order_detail, order: order, product: instrument) }
  let(:reservation) { build_stubbed(:reservation, order_detail: order_detail, product: instrument) }
  let(:template) { double("template") }
  let(:user) { build_stubbed(:user) }

  subject(:presenter) { described_class.new(template, reservation) }

  before :each do
    allow(order_detail).to receive(:accessories?).and_return false
    allow(reservation).to receive(:can_switch_instrument?).and_return true
    allow(reservation).to receive(:can_switch_instrument_off?).and_return false
    allow(reservation).to receive(:can_switch_instrument_on?).and_return false
    allow(reservation).to receive(:startable_now?).and_return false
    allow(reservation).to receive(:can_cancel?).and_return false
    allow(reservation).to receive(:ongoing?).and_return false
  end

  context "#view_edit_link" do
    let(:link) { double "link" }

    context "when not in a current facility" do
      before { allow(template).to receive(:current_facility).and_return nil }

      context "when the user can edit" do
        let(:path) do
          edit_order_order_detail_reservation_path(
            order,
            order_detail,
            reservation,
          )
        end

        it "returns an edit link" do
          expect(reservation).to receive(:can_customer_edit?).and_return true
          expect(presenter).to receive(:link_to).with(reservation, path).and_return link
          expect(presenter.view_edit_link).to eq link
        end
      end

      context "when the user cannot edit" do
        let(:path) do
          order_order_detail_reservation_path(order, order_detail, reservation)
        end

        it "returns a view link" do
          expect(reservation).to receive(:can_customer_edit?).and_return false
          expect(presenter).to receive(:link_to).with(reservation, path).and_return link
          expect(presenter.view_edit_link).to eq link
        end
      end
    end
  end

  context "#user_actions" do
    before :each do
      allow(order_detail).to receive(:reservation).and_return reservation
    end

    subject(:text) { presenter.user_actions.join("|") }

    it "has only report an issue" do
      parts = text.split("|")
      expect(parts).to be_one
      expect(parts.first).to include("Report an Issue")
    end

    describe "switching" do
      let(:encoded_link) { CGI.escapeHTML(link) }
      let(:link) do
        order_order_detail_reservation_switch_instrument_path(
          order,
          order_detail,
          reservation,
          link_args,
        )
      end

      context "can switch on" do
        let(:link_args) { { switch: "on", reservation_started: "on" } }

        before :each do
          expect(reservation)
            .to receive(:can_switch_instrument_on?)
            .and_return true
        end

        it "includes the switch on event" do
          expect(text).to include encoded_link
        end
      end

      context "can switch off" do
        let(:link_args) { { switch: "off", reservation_ended: "on" } }

        before :each do
          expect(reservation)
            .to receive(:can_switch_instrument_off?)
            .and_return true
        end

        it "includes the switch off event" do
          expect(text).to include encoded_link
        end
      end
    end

    describe "canceling" do
      before :each do
        expect(reservation).to receive(:can_cancel?).and_return true
      end

      shared_examples_for "it has a cancellation link with a confirmation" do
        it "includes a cancellation link" do
          expect(text).to include link
        end

        it "includes a confirmation" do
          expect(text).to include "confirm="
        end

        it "returns canceled_at to what it was before" do
          text
          expect(reservation.order_detail.canceled_at).to be_blank
        end
      end

      context "there is a fee" do
        let(:link) do
          cancel_order_order_detail_path(order, order_detail)
        end

        before :each do
          allow(presenter.canceler).to receive(:total_cost).and_return 10
        end

        it_behaves_like "it has a cancellation link with a confirmation"

        it "mentions the cancellation fee" do
          expect(text).to include "Canceling this reservation will incur a $10"
        end
      end

      context "there is not a fee" do
        let(:link) do
          cancel_order_order_detail_path(order, order_detail)
        end

        before :each do
          allow(presenter.canceler).to receive(:total_cost).and_return 0
        end

        it_behaves_like "it has a cancellation link with a confirmation"

        it "does not mention a cancellation fee" do
          expect(text).not_to include "Canceling this reservation will incur a $"
        end
      end
    end

    describe "moving" do
      let(:link) do
        order_order_detail_reservation_move_reservation_path(
          order,
          order_detail,
          reservation,
        )
      end

      before do
        expect(reservation).to receive(:can_switch_instrument?).and_return false
        expect(reservation).to receive(:startable_now?).and_return true
      end

      it "includes the move 'Move Up' link" do
        expect(text).to include link
      end
    end

    describe "accessories" do
      include ReservationsHelper

      let(:link) { reservation_pick_accessories_path(reservation) }

      before do
        expect(reservation).to receive(:ongoing?).and_return true
        expect(order_detail).to receive(:accessories?).and_return true
      end

      it "includes the accessories link" do
        expect(text).to include link
      end
    end
  end
end
