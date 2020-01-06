# frozen_string_literal: true

class ResearchSafetyCertificationLookup

  # Replace the value of this attribute in your engine to connect to the school's
  # custom API.
  cattr_accessor(:adapter_class) { ResearchSafetyAlwaysCertifiedAdapter }

  # This is a class method for easier stubbing in specs
  def self.adapter(user)
    adapter_class.new(user)
  end

  # Allows either a single certificate or an array of certificates
  def self.certified?(user, certificates)
    new(user).certified?(certificates)
  end

  def self.certificates_with_status_for(user)
    new(user).certificates_with_status
  end

  def initialize(user)
    @user = user
  end

  # Allows either a single certificate or an array of certificates
  def certified?(certificates)
    Array(certificates).all? { |certificate| adapter.certified?(certificate) }
  end

  def missing_from(certificates)
    certificates.reject { |certificate| adapter.certified?(certificate) }
  end

  def certificates_with_status
    ResearchSafetyCertificate.ordered.each_with_object({}) do |certificate, hash|
      hash[certificate] = adapter.certified?(certificate)
    end
  end

  private

  # This is memoized so the adapter class can do its own internal caching/memoization
  # For example, it might only make one HTTP request to return all of the user's
  # certifications.
  def adapter
    @adapter ||= self.class.adapter(@user)
  end

end
