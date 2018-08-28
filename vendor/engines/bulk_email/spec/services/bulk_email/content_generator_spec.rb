# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkEmail::ContentGenerator do
  subject { described_class.new(facility) }

  let(:facility) { instrument.facility }
  let(:instrument) { FactoryBot.create(:setup_instrument, :offline) }
  let(:recipient) { FactoryBot.build(:user) }

  describe "#greeting" do
    context "without a recipient name" do
      it "generates a greeting with a placeholder name" do
        expect(subject.greeting).to include("Firstname Lastname")
      end
    end

    context "with a recipient name" do
      it "generates a greeting with a placeholder name" do
        expect(subject.greeting(recipient.full_name))
          .to include(recipient.full_name)
      end
    end

    context "with an offline instrument as a subject_product" do
      subject { described_class.new(facility, instrument) }

      it "includes the instrument name with a downtime reason" do
        expect(subject.greeting)
          .to include("#{instrument.name} has been taken offline")
      end
    end
  end

  describe "#signoff" do
    context "when in a single-facility context" do
      it { expect(subject.signoff).to be_present }
    end

    context "when in a cross-facility context" do
      let(:facility) { Facility.cross_facility }

      it { expect(subject.signoff).to be_blank }
    end
  end

  describe "#subject_prefix" do
    context "when in a single-facility context", :locales do
      before do
        set_translation("bulk_email.subject_prefix_with_facility",
                        "[!app_name! %{name} (%{abbreviation})]")
      end

      it "includes the app, facility name, and abbreviation" do
        expect(subject.subject_prefix)
          .to include(I18n.t("app_name"))
          .and include(facility.name)
          .and include(facility.abbreviation)
      end
    end

    context "when in a cross-facility context" do
      let(:facility) { Facility.cross_facility }

      it "includes only the app name" do
        expect(subject.subject_prefix).to eq("[#{I18n.t('app_name')}]")
      end
    end
  end

  describe "#wrap_text" do
    subject { described_class.new(facility, instrument) }

    it "wraps content with the greeting and signoff" do
      expect(subject.wrap_text("This is some text"))
        .to include(subject.greeting)
        .and include("This is some text")
        .and include(subject.signoff)
    end
  end
end
