# frozen_string_literal: true

require "spec_helper"

RSpec.describe ArrayUtil do
  let(:array) { [:a, :b, :c] }

  describe "insert_before" do
    it "can insert before the first element" do
      ArrayUtil.insert_before(array, :new, :a)
      expect(array).to eq([:new, :a, :b, :c])
    end

    it "can insert in the middle" do
      ArrayUtil.insert_before(array, :new, :b)
      expect(array).to eq([:a, :new, :b, :c])
    end

    it "inserts at the end if not found" do
      ArrayUtil.insert_before(array, :new, :not_found)
      expect(array).to eq([:a, :b, :c, :new])
    end
  end

  describe "insert_after" do
    it "can insert after the first element" do
      ArrayUtil.insert_after(array, :new, :a)
      expect(array).to eq([:a, :new, :b, :c])
    end

    it "can insert in the middle" do
      ArrayUtil.insert_after(array, :new, :b)
      expect(array).to eq([:a, :b, :new, :c])
    end

    it "can insert after the last element" do
      ArrayUtil.insert_after(array, :new, :c)
      expect(array).to eq([:a, :b, :c, :new])
    end

    it "inserts at the end if not found" do
      ArrayUtil.insert_after(array, :new, :not_found)
      expect(array).to eq([:a, :b, :c, :new])
    end
  end

end
