# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavTab::Link do
  let(:cross_facility) { false }
  let(:link) do
    described_class.new(
      cross_facility:,
      tab:,
      text:,
      url:,
    )
  end
  let(:tab) { "admin_billing" }
  let(:text) { nil }
  let(:url) { nil }

  describe "#active?" do
    let(:active_tab) { nil }
    let(:cross_facility?) { nil }
    let(:controller) do
      OpenStruct.new(active_tab:, cross_facility?: cross_facility?)
    end
    subject { link.active?(controller) }

    context "when the current controller tab name matches" do
      let(:active_tab) { "admin_billing" }

      context "when the controller is in a cross-facility context" do
        let(:cross_facility?) { true }

        context "and the tab is cross-facility" do
          let(:cross_facility) { true }

          it { is_expected.to be true }
        end

        context "and the tab is not cross-facility" do
          it { is_expected.to be false }
        end
      end

      context "when the controller is in a single facility context" do
        let(:cross_facility?) { false }

        context "and the tab is cross-facility" do
          let(:cross_facility) { true }

          it { is_expected.to be false }
        end

        context "and the tab is not cross-facility" do
          it { is_expected.to be true }
        end
      end
    end

    context "when the current controller tab name does not match" do
      it { is_expected.to be false }
    end
  end

  describe "#tab_id" do
    subject { link.tab_id }

    context "when the tab is defined", :locales do
      before { set_translation("pages.a_named_tab", "A Tab") }
      let(:tab) { "a_named_tab" }

      it { is_expected.to eq("a_named_tab_tab") }
    end

    context "when the tab is undefined" do
      let(:tab) { nil }

      it { is_expected.to be nil }
    end
  end

  describe "#to_html" do
    let(:text) { "Label" }
    subject { link.to_html }

    context "when the url is defined" do
      let(:url) { "/link/1" }

      it { is_expected.to eq('<a href="/link/1">Label</a>') }
    end

    context "when no url is defined" do
      it { is_expected.to eq("Label") }
    end
  end
end
