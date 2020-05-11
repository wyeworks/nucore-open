# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductPresenter do

  describe "to_s" do
    subject(:presenter) { described_class.new(product) }

    describe "is archived" do
      let(:product) { build(:item, name: "Widget", is_archived: true) }

      it "has the inactive tag on it" do
        expect(presenter.to_s).to eq("Widget (Inactive)")
      end
    end

    describe "is hidden" do
      let(:product) { build(:item, name: "Widget", is_hidden: true) }

      it "has the hidden tag on it" do
        expect(presenter.to_s).to eq("Widget (Hidden)")
      end
    end

    describe "is both archived and hidden" do
      let(:product) { build(:item, name: "Widget", is_archived: true, is_hidden: true) }

      it "has both tags on it" do
        expect(presenter.to_s).to eq("Widget (Hidden) (Inactive)")
      end
    end

    describe "is active and visible" do
      let(:product) { build(:item, name: "Widget") }

      it "is just the name" do
        expect(presenter.to_s).to eq("Widget")
      end
    end
  end
end
