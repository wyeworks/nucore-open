# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::CardReader do
  it { is_expected.to validate_presence_of :product_id }
  it { is_expected.to validate_presence_of :card_reader_number }

  describe "card_reader_number" do
    it { is_expected.to validate_presence_of :control_device_number }

    it { is_expected.to allow_value("00:00:00:00:00:00").for(:control_device_number) }
    it { is_expected.to allow_value("FF:FF:FF:FF:FF:FF").for(:control_device_number) }

    describe "valid after transformations" do
      it { is_expected.to allow_value("ff:ff:ff:ff:ff:ff").for(:control_device_number) }
      it { is_expected.to allow_value("00-00-00-00-00-00").for(:control_device_number) }
    end

    it { is_expected.not_to allow_value("12345").for(:control_device_number) }
    it { is_expected.not_to allow_value("GG:GG:GG:GG:GG:GG").for(:control_device_number) }
    it { is_expected.not_to allow_value("F:F:F:F:F:F").for(:control_device_number) }
    it { is_expected.not_to allow_value("0:0:0:0:0:0").for(:control_device_number) }

    it "upcases" do
      subject.control_device_number = "ff:ff:ff:ff:ff:ff"
      subject.valid?
      expect(subject.control_device_number).to eq("FF:FF:FF:FF:FF:FF")
    end

    it "replaces dashes with colons" do
      subject.control_device_number = "00-00-00-00-00-00"
      subject.valid?
      expect(subject.control_device_number).to eq("00:00:00:00:00:00")
    end
  end

  describe "with a product" do
    let(:product) { create(:secure_room) }
    subject { described_class.new(secure_room: product, control_device_number: "00:00:00:00:00:00") }

    it { is_expected.to validate_uniqueness_of(:card_reader_number).scoped_to(:control_device_number).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:tablet_token).case_insensitive }
  end

  describe "direction_in" do
    describe "default" do
      it { is_expected.to be_ingress }
      it { is_expected.not_to be_egress }
      it "has 'In' for direction" do
        expect(subject.direction).to eq("In")
      end
    end

    describe "when set to false" do
      before { subject.direction_in = false }

      it { is_expected.to be_egress }
      it { is_expected.not_to be_ingress }
      it "has 'Out' for direction" do
        expect(subject.direction).to eq("Out")
      end
    end
  end

  describe "tablet_token" do
    it "sets a token on create" do
      reader = build(:card_reader)
      expect(reader.tablet_token).to be_blank
      reader.save
      expect(reader.tablet_token).to match(/\A[A-Z]{12}\z/)
    end

    it "does not change the token later" do
      reader = create(:card_reader)
      expect { reader.save }.not_to change(reader, :tablet_token)
    end
  end
end
