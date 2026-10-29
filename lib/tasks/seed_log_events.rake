# frozen_string_literal: true

# This is here mostly to seed the LogEvents table so the UI can be tested.
# We might also want to run it in production to give partial historical
# data

namespace :log_events do
  task seed: :environment do
    Account.transaction do
      Account.all.each do |account|
        next if LogEvent.where(loggable: account).present?
        LogEvent.log(
          account, :create, User.find_by(id: account.created_by),
          event_time: account.created_at)

        next if account.updated_at.blank?
        LogEvent.log(
          account, :update, User.find_by(id: account.updated_by),
          event_time: account.updated_at)
      end

      AccountUser.all.each do |account_user|
        next if LogEvent.where(loggable: account_user).present?
        LogEvent.log(
          account_user, :create, User.find_by(id: account_user.created_by),
          event_time: account_user.created_at)

        next if account_user.deleted_at.blank?
        LogEvent.log(
          account_user, :delete, User.find_by(id: account_user.deleted_by),
          event_time: account_user.deleted_at)
      end

      User.all.each do |user|
        next if LogEvent.where(loggable: user).present?
        LogEvent.log(user, :create, nil, event_time: user.created_at)
      end
    end
  end
end
