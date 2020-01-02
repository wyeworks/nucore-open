# frozen_string_literal: true

module NuResearchSafety

  class OrderCertificateValidator

    include TextHelpers::Translation

    attr_reader :order_details, :all_missing_certificates

    def initialize(order_details)
      @order_details = order_details
    end

    def valid?
      return true if order_details.first.ordered_on_behalf_of?

      invalid_order_details = order_details.reject do |od|
        valid_order_detail?(od)
      end
      invalid_order_details.none?
    end

    def error_message
      error_for(@all_missing_certificates)
    end

    def translation_scope
      "validators.#{self.class.name.underscore}"
    end

    private

    def missing_certificates_for(product)
      product.certificates.reject do |cert|
        certificate_cache[cert]
      end
    end

    def valid_order_detail?(od)
      missing_certs = missing_certificates_for(od.product)
      if missing_certs.none?
        true
      else
        @all_missing_certificates ||= Set.new
        @all_missing_certificates.merge(missing_certs)
        od.errors.add(:base, error_for(missing_certs))
        false
      end
    end

    def certificate_cache
      user = order_details.first.user
      @certificate_cache ||= Hash.new do |hash, certificate|
        hash[certificate] = NuResearchSafety::CertificationLookup.certified?(user, certificate)
      end
    end

    def error_for(missing_certs)
      cert_names = missing_certs.map(&:name).join(", ")
      html("missing_html", certificates: cert_names, inline: true)
    end

  end

end
