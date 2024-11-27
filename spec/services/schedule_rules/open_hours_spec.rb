# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScheduleRules::OpenHours do
  let(:product) do
    create(
      :setup_instrument,
      :always_available
    )
  end
  let(:schedule_rules) { product.schedule_rules }

  it { expect(described_class.weekdays).to eq Date::ABBR_DAYNAMES }

  before do
    product.schedule_rules.destroy_all
  end

  context "#per_weekday groups open hours by weekday" do
    let(:subject) { described_class.new(schedule_rules).per_weekday }

    before do
      create(
        :schedule_rule,
        :weekday,
        product:,
        start_hour: 9,
        start_min: 0,
        end_hour: 17,
        end_min: 0,
      )
    end

    it { is_expected.to be_a Hash }
    it { expect(subject.keys).to eq(described_class.weekdays) }
    it { expect(subject.values.compact.all?(String)).to be true }

    context "weekday, single schedule rule" do
      let(:schedule_rule) { schedule_rules.first }
      let(:open_hours) { [schedule_rule.start_time, schedule_rule.end_time].join(" - ") }

      it { expect(subject.values.compact).to eq([open_hours] * 5) }
    end

    context "weekday with discontinuous schedule rules" do
      let!(:special_schedule_rule) do
        create(
          :schedule_rule,
          :weekday,
          product:,
          start_hour: 0,
          start_min: 0,
          end_hour: 1,
          end_min: 0,
        )
      end

      it "handles discontinuous rules correctly" do
        expect(subject["Mon"]).to eq("0:00 - 1:00, 9:00 - 17:00")
      end
    end

    context "weekday with continuous schedule rules" do
      let!(:special_schedule_rule) do
        create(
          :schedule_rule,
          :weekday,
          product:,
          start_hour: 0,
          start_min: 0,
          end_hour: 9,
          end_min: 0,
        )
      end

      it "handles discontinuous rules correctly" do
        expect(subject["Mon"]).to eq("0:00 - 17:00")
      end
    end
  end
end
