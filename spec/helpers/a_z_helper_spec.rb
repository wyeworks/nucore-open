# frozen_string_literal: true

require "rails_helper"

RSpec.describe AZHelper do
  describe "build_az_list" do
    let(:facilities) do
      [
        FactoryBot.build(:facility, name: "Alpha"),
        FactoryBot.build(:facility, name: "Alpha2"),
        FactoryBot.build(:facility, name: "Delta"),
        FactoryBot.build(:facility, name: "delta2"),
      ]
    end

    let(:az_list) { helper.build_az_list(facilities) }

    it "puts all the A's together" do
      expect(az_list["A"].map(&:name)).to contain_exactly("Alpha", "Alpha2")
    end

    it "has an empty array for not-found letters" do
      expect(az_list["B"]).to eq([])
    end

    it "groups lowercase and uppercase together" do
      expect(az_list["D"].map(&:name)).to contain_exactly("Delta", "delta2")
    end
  end
end
