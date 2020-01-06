# frozen_string_literal: true

class OrderResearchSafetyCertificationValidator

  include TextHelpers::Translation

  attr_reader :order_details

  def initialize(order_details)
    @order_details = order_details
  end

  def valid?
    return true if order_details.first.ordered_on_behalf_of?

    order_details.each do |order_detail|
      missing_certs = missing_certificates_for(order_detail)
      # Add the missing certificates specifically for each order detail
      order_detail.errors.add(:base, error_for(missing_certs)) if missing_certs.any?
    end

    all_missing_certificates.none?
  end

  def error_message
    error_for(all_missing_certificates)
  end

  def translation_scope
    "validators.#{self.class.name.underscore}"
  end

  def all_missing_certificates
    @all_missing_certificates ||= ResearchSafetyCertificationLookup.new(user).missing_from(all_required_certificates)
  end

  private

  def all_required_certificates
    @all_required_certificates ||= order_details.flat_map do |order_detail|
      order_detail.product.research_safety_certificates
    end.uniq
  end

  def user
    order_details.first.user
  end

  def missing_certificates_for(order_detail)
    order_detail.product.research_safety_certificates & all_missing_certificates
  end

  def error_for(missing_certs)
    cert_names = missing_certs.map(&:name).join(", ")
    html("missing_html", certificates: cert_names, inline: true)
  end

end
