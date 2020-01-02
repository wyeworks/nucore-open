# frozen_string_literal: true

module NuResearchSafety

  module CertificatesHelper

    def delete_certificate_link(certificate)
      link_to(
        text("views.nu_research_safety.certificates.index.remove.label"),
        certificate_path(certificate),
        data: { confirm: text("views.nu_research_safety.certificates.index.remove.confirm", name: certificate.name) },
        method: :delete,
      )
    end

    def edit_certificate_link(certificate)
      link_to(text("admin.shared.edit", model: NuResearchSafety::Certificate.model_name.human),
              edit_certificate_path(certificate))
    end

  end

end
