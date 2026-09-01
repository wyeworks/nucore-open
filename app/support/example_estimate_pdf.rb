# frozen_string_literal: true

class ExampleEstimatePdf < EstimatePdf
  include OrdersPdfHelper

  def generate(pdf)
    generate_facility_header(pdf)
    generate_document_header(pdf)
    generate_contact_info(pdf) if facility.has_contact_info?

    generate_order_detail_rows(pdf)

    generate_document_footer(pdf)
  end

  private

  def generate_document_header(pdf)
    pdf.text "Estimate ##{estimate.id}", size: 15
    pdf.move_down 10

    pdf.font_size = 10.5

    rows = [
      [:created_at, I18n.l(estimate.created_at)],
      [:expires_at, I18n.l(estimate.expires_at)],
      [:user_display_name, estimate.user_display_name],
    ]

    rows << [:note, estimate.note] if estimate.note.present?

    rows.each do |key, value|
      label = Estimate.human_attribute_name(key)
      pdf.text "<b>#{label}:</b> #{value}", inline_format: true
    end
    pdf.move_down(10)
  end

  def generate_order_detail_rows(pdf)
    pdf.move_down(30)
    pdf.table([estimate_detail_headers] + estimate_detail_rows, header: true, width: 510) do
      row(0).style(LABEL_ROW_STYLE)
      column(0).width = 200
      column(1).width = 70
      column(2).width = 70
      column(3).width = 70
      column(3).style(align: :right)
      column(4).style(align: :right)
    end

    pdf.move_down 10
    pdf.text(
      "Total: #{number_to_currency(estimate.total_cost)}",
      align: :right,
      style: :bold,
    )
  end

  def estimate_detail_headers
    [
      Product.model_name.human,
      EstimateDetail.human_attribute_name(:quantity),
      EstimateDetail.human_attribute_name(:duration),
      EstimateDetail.human_attribute_name(:unit_cost),
      EstimateDetail.human_attribute_name(:cost),
    ]
  end

  def estimate_detail_rows
    estimate.estimate_details.includes(:product).map do |estimate_detail|
      estimate_detail_presenter = EstimateDetailPresenter.new(estimate_detail)

      [
        estimate_detail_presenter.product_display,
        estimate_detail_presenter.quantity,
        estimate_detail_presenter.duration_display,
        estimate_detail_presenter.unit_cost_disaply,
        estimate_detail_presenter.cost_display,
      ]
    end
  end
end
