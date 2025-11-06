# frozen_string_literal: true

require "nucore"

ActiveRecord::Base.class_eval do
  def self.validate_url_name(attr_name, scope = nil)
    validates attr_name, presence: true
    validates attr_name, length: { in: 3..50 }
    validates attr_name, format: { with: /\A[\w-]+\z/, message: "may contain letters, digits, dashes and underscores only" }
    if scope.present?
      validates attr_name, uniqueness: { scope: scope, case_sensitive: false }
    else
      validates attr_name, uniqueness: { case_sensitive: false }
    end
  end
end

#
# Log info about how each user is authenticated.
# In the future we may want to record in the DB the means
# by which auth happened.
Warden::Manager.after_authentication do |user, auth, _opts|
  Rails.logger.info "User #{user.username} authenticated via #{auth.winning_strategy.class} at #{user.current_sign_in_at}"
end
