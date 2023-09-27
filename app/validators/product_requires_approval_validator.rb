# frozen_string_literal: true

class ProductRequiresApprovalValidator < ActiveModel::Validator

  def validate(record)
    return if record.product.blank?
    unless record.product.requires_approval?
      record.errors.add(:product, I18n.t("activerecord.errors.models.training_request.product.requires_no_approval"))
    end
  end

end
