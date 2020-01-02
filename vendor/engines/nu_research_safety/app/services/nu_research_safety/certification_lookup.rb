module NuResearchSafety

  class CertificationLookup

    def self.certified?(user, certificate)
      Nu::ResearchSafetyCertificationAdapter.new(user).certified?(certificate)
    end

    def self.certificates_with_status_for(user)
      NuResearchSafety::Certificate.ordered.each_with_object({}) do |certificate, hash|
        hash[certificate] = certified?(user, certificate)
      end
    end

  end

end
