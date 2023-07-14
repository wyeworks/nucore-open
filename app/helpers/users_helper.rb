# frozen_string_literal: true

module UsersHelper

  # Builds the text for the creation success flash notice
  def creation_success_flash_text(user, facility)
    html(
      "controllers.users.create.success.#{translation_key(user)}",
      user_info: "#{user.full_name} (#{user.username})",
      user_link: facility_user_path(facility, user),
      price_group: price_group_name(user),
      app_name: t("app_name"),
      support_contact:
    )
  end

  private

  def translation_key(user)
    name = price_group_name(user)

    if name == PriceGroup.base.name
      "internal"
    elsif name == PriceGroup.external.name
      "external"
    else
      name.parameterize(separator: '_')
    end
  end

  def price_group_name(user)
    user.default_price_group.name
  end

  def support_contact
    if Settings.support_email.blank?
      ""
    else
      email = Settings.support_email
      " at [#{email}](mailto:#{email})"
    end
  end

end
