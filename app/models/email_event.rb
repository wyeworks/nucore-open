# frozen_string_literal: true

# Never instantiate this class directly. Use the `notify` method.
class EmailEvent < ApplicationRecord

  belongs_to :user
  validates :user, presence: true
  validates :key, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }

  # Use this to avoid sending too many emails to a user within a given timeframe
  # It accepts a block, and will yield if this method has not been called within
  # the wait time.
  #
  # Example:
  #
  # EmailEvent.notify(file.user, [:some_mailer, :some_action], wait: 1.hour) do
  #   SomeMailer.some_action(user).deliver_later
  # end
  #
  def self.notify(user, keys, wait: 24.hours)
    event = find_or_initialize_by(user: user, key: key_for(keys))

    if event.last_sent_at.blank? || event.last_sent_at < wait.ago
      # if a race condition makes event invalid now, we don't yield
      yield if event.update(last_sent_at: Time.current)
    end
  rescue ActiveRecord::RecordNotUnique
    # Do nothing, we're in a race condition with another new EmailEvent. Let that one win.
  end

  def self.key_for(keys)
    Array(keys).map(&:to_s).join("/")
  end

end
