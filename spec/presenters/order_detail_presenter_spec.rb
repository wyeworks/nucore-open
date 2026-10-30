# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailPresenter do
  let(:presented) { OrderDetailPresenter.new(order_detail) }
  let(:order_detail) { build_stubbed(:order_detail) }

  RSpec.shared_context "order with a reservation" do
    let(:facility) { order_detail.facility }
    let(:order) { order_detail.order }
    let(:order_detail) { reservation.order_detail }
    let(:reservation) { create(:setup_reservation) }
  end

  describe "#description_as_html" do
    subject { presented.description_as_html }

    let(:product) { build_stubbed(:product, name: "<Micro> & >Scope<") }

    before(:each) do
      allow(order_detail).to receive(:bundle) { bundle }
      allow(order_detail).to receive(:product) { product }
    end

    context "when part of a bundle" do
      let(:bundle) { build_stubbed(:bundle, name: ">Bun & dle<") }

      it { is_expected.to eq("&gt;Bun &amp; dle&lt; &mdash; &lt;Micro&gt; &amp; &gt;Scope&lt;") }
      it { is_expected.to be_html_safe }
    end

    context "when not part of a bundle" do
      let(:bundle) { nil }

      it { is_expected.to eq("&lt;Micro&gt; &amp; &gt;Scope&lt;") }
      it { is_expected.to be_html_safe }
    end
  end

  describe "#description_as_text" do
    subject { presented.description_as_text }

    let(:product) { build_stubbed(:product, name: "<Micro> & >Scope<") }

    before(:each) do
      allow(order_detail).to receive(:bundle) { bundle }
      allow(order_detail).to receive(:product) { product }
    end

    context "when part of a bundle" do
      let(:bundle) { build_stubbed(:bundle, name: ">Bun & dle<") }

      it { is_expected.to eq(">Bun & dle< -- <Micro> & >Scope<") }
      it { is_expected.to be_html_safe }
    end

    context "when not part of a bundle" do
      let(:bundle) { nil }

      it { is_expected.to eq("<Micro> & >Scope<") }
      it { is_expected.to be_html_safe }
    end
  end

  describe "#description_as_html_with_facility_prefix" do
    subject { presented.description_as_html_with_facility_prefix }

    include_context "order with a reservation"

    before { facility.abbreviation = "ABC" }

    it { is_expected.to eq("ABC / #{presented.description_as_html}") }
    it { is_expected.to be_html_safe }
  end

  describe "#row_class" do
    subject { presented.row_class }

    before { allow(order_detail).to receive(:reconciled?) { reconciled? } }

    context "when reconciled" do
      let(:reconciled?) { true }

      it { is_expected.to eq("") }
    end

    context "when not reconciled" do
      let(:reconciled?) { false }

      before { allow(order_detail).to receive(:fulfilled_at) { fulfilled_at } }

      context "and not fulfilled" do
        let(:fulfilled_at) { nil }

        it { is_expected.to eq("") }
      end

      context "and fulfilled" do
        context "fewer than 60 days ago" do
          let(:fulfilled_at) { 59.days.ago }

          it { is_expected.to eq("") }
        end

        context "more than 60 days ago" do
          let(:fulfilled_at) { 61.days.ago }

          it { is_expected.to eq("reconcile-warning") }
        end
      end
    end
  end

  describe "#show_order_path" do
    subject { presented.show_order_path }

    include_context "order with a reservation"

    it { is_expected.to eq("/#{facilities_route}/#{facility.url_name}/orders/#{order.id}") }
  end

  describe "#show_order_detail_path" do
    subject { presented.show_order_detail_path }

    include_context "order with a reservation"

    it { is_expected.to eq("/orders/#{order.id}/order_details/#{order_detail.id}") }
  end

  describe "#wrapped_total" do
    subject { presented.wrapped_total }
    let(:order) { FactoryBot.create(:setup_order, product:) }
    let(:order_detail) { order.order_details.first }
    let(:product) { FactoryBot.create(:setup_item) }

    before { product.price_policies.update_all(unit_cost: "12.34") }

    it { is_expected.to match(%r{\A<span .+>\$12\.34</span>\z}) }
  end
end
