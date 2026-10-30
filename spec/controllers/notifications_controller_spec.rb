# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "notifications_helper"

RSpec.shared_examples "user without notifications" do
  context "director without notices" do
    before :each do
      @director.notifications.each(&:destroy)
    end

    it_should_allow :director, "no access to notifications if there aren't any" do
      is_expected.to set_flash
      assert_redirected_to root_path
    end
  end
end

RSpec.describe NotificationsController do
  include NotificationsHelper

  before :each do
    create_users
    request.env["HTTP_REFERER"] = root_path

    facility_users.each do |usr|
      create_merge_notification_subject
      MergeNotification.create_for! instance_variable_get("@#{usr}"), @order_detail
    end
  end

  context "index" do
    before :each do
      @authable = create(:facility)
      @method = :get
      @action = :index
    end

    it_should_require_login

    it_should_behave_like "user without notifications"

    it_should_allow_all facility_users do |user|
      expect(assigns(:notices).size).to eq(user.notifications.active.count)
      is_expected.to render_template "index"
    end
  end

  # context 'update' do
  #  before :each do
  #    @method=:put
  #    @action=:update
  #    @params={ :id => Notification.first.id }
  #  end
  #
  #  it_should_require_login
  #
  #  it_should_behave_like 'user without notifications'
  #
  #  facility_users.each do |usr_sym|
  #    context "as #{usr_sym}" do
  #      before :each do
  #        @user=instance_variable_get "@#{usr_sym}"
  #        @notice=@user.notifications.first
  #        @params[:id]=@notice.id
  #      end
  #
  #      it_should_allow usr_sym do
  #        assigns(:notices).size.should == 1
  #        @notice.reload.dismissed_at.should_not be_nil
  #        response.body.should be_blank
  #      end
  #    end
  #  end
  # end
end
