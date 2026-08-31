# frozen_string_literal: true

##
# Common sections sed for estimates and statements pdfs.
#
# Assumes `facility` reader method is defined.
module OrdersPdfHelper
  def generate_facility_header(pdf)
    pdf.text facility.to_s, size: 20, style: :bold
  end

  def generate_document_footer(pdf)
    pdf.number_pages "Page <page> of <total>", at: [0, -15]
  end

  def generate_contact_info(pdf)
    pdf.text facility.address if facility.address
    pdf.move_down(10)

    %w(phone_number fax_number email).each do |contact_field|
      field_value = facility.send(contact_field.to_sym)
      next if field_value.blank?
      pdf.text "<b>#{contact_field.titleize}:</b> #{field_value}", inline_format: true
    end
  end

end
