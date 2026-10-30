# frozen_string_literal: true

class Users::ActiveUserFinder
  # Format active users as a CSV
  def active_users_csv(_time = 1.year.ago)
    user_rows = active_users.map { |u| user_fields(u).join(",") }
    user_rows.join("\n")
  end

  # Finds all users that have either signed in or started creating an order in the last year
  def active_users(time = 1.year.ago)
    users = User.joins(:orders)
                .where("orders.created_at > :ago OR last_sign_in_at > :ago", ago: time)
                .select("distinct users.id, users.email,users.username, users.first_name, users.last_name, last_sign_in_at")
  end

  private

  def user_fields(user)
    [user.id,
     user.email,
     user.username,
     user.first_name,
     user.last_name,
     user.last_sign_in_at,
     user.orders.last.try(:created_at)]
  end
end
