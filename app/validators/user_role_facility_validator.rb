# frozen_string_literal: true

class UserRoleFacilityValidator < ActiveModel::Validator
  def validate(record)
    if record.facility_id.present?
      record.errors.add(:role, I18n.t("activerecord.errors.models.user_role.global_cannot_have_facility", role: record.role)) if record.global_role?
    elsif record.facility_role?
      record.errors.add(:role, I18n.t("activerecord.errors.models.user_role.role_must_have_facility", role: record.role))
    end
  end
end
