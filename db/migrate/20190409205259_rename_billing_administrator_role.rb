# frozen_string_literal: true

class RenameBillingAdministratorRole < ActiveRecord::Migration[5.0]
  def up
    # unscoped to allow migrations to run despite acts_as_paranoid
    # https://github.com/rubysherpas/paranoia/issues/226
  	UserRole.unscoped.where(role: "Billing Administrator").each do |user|
  		user.role = "Global Billing Administrator"
  		user.save!
  	end
  end

  def down
    # unscoped to allow migrations to run despite acts_as_paranoid
    # https://github.com/rubysherpas/paranoia/issues/226
  	UserRole.unscoped.where(role: "Global Billing Administrator").each do |user|
  		user.role = "Billing Administrator"
  		user.save!
  	end
  end
end
