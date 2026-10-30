# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewHook do
  let(:view_hook) { described_class.new }

  describe "find" do
    before do
      view_hook.add_hook("view1", "placement1", "partial")
      view_hook.add_hook("view1", "placement1", "partial2")
    end

    it "returns the correct partials" do
      expect(view_hook.find("view1", "placement1")).to eq(%w[partial partial2])
    end

    it "returns an empty array if the view is not found" do
      expect(view_hook.find("view2", "placement1")).to eq([])
    end

    it "returns an empty array if the placement is not found" do
      expect(view_hook.find("view1", "placement2")).to eq([])
    end

    it "finds using symbols" do
      expect(view_hook.find(:view1, :placement1)).to eq(%w[partial partial2])
    end
  end

  describe "adding with symbols" do
    before do
      view_hook.add_hook(:view1, :placement, :partial)
    end

    it "finds by symbol" do
      expect(view_hook.find(:view1, :placement)).to eq(["partial"])
    end

    it "finds by string" do
      expect(view_hook.find("view1", "placement")).to eq(["partial"])
    end
  end

  describe "removing" do
    before do
      view_hook.add_hook(:view1, :placement, :partial)
    end

    it "removes with symbols" do
      view_hook.remove_hook(:view1, :placement, :partial)
      expect(view_hook.find(:view1, :placement)).to be_empty
    end

    it "removes with strings" do
      view_hook.remove_hook("view1", "placement", "partial")
      expect(view_hook.find(:view1, :placement)).to be_empty
    end
  end

  describe "render_view_hook" do
    let(:context) { double }
    before do
      view_hook.add_hook("view1", "placement1", "partial")
      view_hook.add_hook("view1", "placement1", "partial2")
    end

    it "returns the partials concatenated" do
      expect(context).to receive(:render).with("partial", a: 1).and_return("<p>rendered partial 1</p>".html_safe)
      expect(context).to receive(:render).with("partial2", a: 1).and_return("<p>rendered partial 2</p>".html_safe)

      output = view_hook.render_view_hook("view1", "placement1", context, a: 1)
      expect(output).to eq("<p>rendered partial 1</p><p>rendered partial 2</p>")
    end
  end
end
