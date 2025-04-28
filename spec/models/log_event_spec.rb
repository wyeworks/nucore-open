# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogEvent do

  describe "loggable" do
    describe "with a user" do
      let(:user) { create(:user) }
      let(:log_event) { create(:log_event, loggable: user) }

      it "gets the loggable" do
        expect(log_event.reload.loggable).to eq(user)
      end
    end

    describe "with something that is soft-deleted" do
      let(:user_role) { create(:user_role, :facility_staff, deleted_at: Time.current) }
      let(:log_event) { create(:log_event, loggable: user_role) }

      it "can still find it" do
        expect(log_event.reload.loggable).to eq(user_role)
      end
    end
  end

  describe "with_events" do
    let(:loggable1) { create(:user) }
    let(:loggable2) { create(:facility) }
    let(:event_type) { "some_event_happened" }

    before do
      LogEvent.log(loggable1, event_type, nil)
      LogEvent.log(loggable2, event_type, nil)
      LogEvent.log(loggable1, "other_event_type", nil)
    end

    context "when filtering by event_type" do
      let(:subject) { described_class.with_events([event_type]) }

      it "returns 2 elements" do
        expect(subject.count).to eq 2
      end
    end

    context "when filtering by loggable_type.event_type" do
      let(:subject) { described_class.with_events(["user.#{event_type}"]) }

      it "returns 1 element" do
        expect(subject.count).to eq 1
      end
    end
  end
end
