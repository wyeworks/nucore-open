# frozen_string_literal: true

require "rails_helper"
require "notifications_helper"

RSpec.describe MergeNotification do
  include NotificationsHelper

  before :each do
    @subject = create_merge_notification_subject
    MergeNotification.create_for! @user, @subject
  end

  [:user_id, :subject_id, :notice].each do |field|
    it { is_expected.to validate_presence_of field }
  end

  it "should create for user by subject" do
    notices = MergeNotification.all
    expect(notices.size).to eq(1)
    notice = notices.first
    expect(notice.user).to eq(@user)
    expect(notice.subject).to eq(@subject)
    expect(notice.notice).to eq(@subject.to_notice(MergeNotification, @user))
  end

  context "scopes" do
    before :each do
      @subject2 = create_merge_notification_subject
      MergeNotification.create_for! @user, @subject2
    end

    it "should find notifications by subject" do
      notices = MergeNotification.about(@subject2)
      expect(notices.size).to eq(1)
      expect(notices.first.subject).to eq(@subject2)
    end

    it "should find non dismissed notifications" do
      notification = MergeNotification.about(@subject2).first
      notification.update_attribute :dismissed_at, Time.zone.now
      notices = MergeNotification.active
      expect(notices.size).to eq(1)
      expect(notices.first.subject).to eq(@subject)
    end
  end
end
