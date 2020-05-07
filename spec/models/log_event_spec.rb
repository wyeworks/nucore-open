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
end
