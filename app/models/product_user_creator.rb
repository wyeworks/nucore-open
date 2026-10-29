# frozen_string_literal: true

class ProductUserCreator
  def self.create(user:, product:, approver:)
    product_user = ProductUser.new(
      product:,
      user:,
      approved_by: approver.id,
      approved_at: Time.zone.now,
    )

    product_user.transaction do
      product_user.save && manage_training_request(product_user)
    end
    product_user
  end

  def self.manage_training_request(product_user)
    training_request = TrainingRequest.from_product_user(product_user).first || return
    product_user.update_attribute(:requested_at, training_request.created_at)
    training_request.destroy || raise(ActiveRecord::Rollback)
  end
end
