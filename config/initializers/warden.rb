# frozen_string_literal: true

Warden::Manager.after_set_user do |user, auth, _opts|
  next unless Settings.login.disabled

  unless user.administrator?
    auth.logout
    throw(:warden, message: Settings.login.disabled_error)
  end
end
