# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailListAttribute do

  class TestEmailListAttribute

    include ActiveModel::Validations

    attr_accessor :emails

    include EmailListAttribute

    email_list_attribute :emails

    # Mimic ActiveRecord's [] methods
    def []=(key, value)
      instance_variable_set("@#{key}", value)
    end

    def [](key)
      instance_variable_get("@#{key}")
    end

  end

  describe "setting the values" do
    let(:object) { TestEmailListAttribute.new }

    it "can set as a string and retrieve the values as a string" do
      object.emails = "test1@example.com, test2@example.com"
      expect(object.emails.to_s).to eq("test1@example.com, test2@example.com")
    end

    it "can set as a string and retrieve as an array" do
      object.emails = "test1@example.com, test2@example.com"
      expect(object.emails.to_a).to eq(["test1@example.com", "test2@example.com"])
    end
  end

  describe "validation" do
    let(:object) { TestEmailListAttribute.new }

    it "is valid when blank" do
      object.emails = ""
      expect(object).to be_valid
    end

    it "is valid with a single email" do
      object.emails = "test@example.com"
      expect(object).to be_valid
    end

    it "is valid with multiple emails" do
      object.emails = "test1@example.com, test2@example.com"
      expect(object).to be_valid
    end

    it "is invalid for a string without a @" do
      object.emails = "test"
      expect(object).to be_invalid
      expect(object.errors).to be_added(:emails, :invalid)
    end

    it "is invalid for an email starting with a @" do
      object.emails = "test@example.com, @test.com"
      expect(object).to be_invalid
      expect(object.errors).to be_added(:emails, :invalid)
    end

    it "is invalid for an email ending with a @" do
      object.emails = "test@example.com, test@"
      expect(object).to be_invalid
      expect(object.errors).to be_added(:emails, :invalid)
    end
  end
end
