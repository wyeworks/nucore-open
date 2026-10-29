# frozen_string_literal: true

module AffiliatesHelper
  def delete_affiliate_link(affiliate)
    link_to(
      I18n.t("affiliates.remove.label"),
      affiliate_path(affiliate),
      confirm: I18n.t("affiliates.remove.confirm", name: affiliate.name),
      method: :delete,
    )
  end

  def edit_affiliate_link(affiliate)
    link_to I18n.t("affiliates.edit"), edit_affiliate_path(affiliate)
  end

  def select_affiliate_options
    Affiliate
      .alphabetical
      .sort_by { |a| [a.other? ? 1 : 0, a.name] } # Force "Other" to be last
      .map do |affiliate|
        [
          affiliate.name,
          affiliate.id,
          { data: { subaffiliates_enabled: affiliate.subaffiliates_enabled? } },
        ]
      end
  end
end
