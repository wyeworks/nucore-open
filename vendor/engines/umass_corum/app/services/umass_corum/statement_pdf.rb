# frozen_string_literal: true

# 1 inch = 72 points
# In general, we should use points when dealing with font-relational measurements,
# but we can use inches when dealing with graphics and page layout.
require "prawn/measurement_extensions"

module UmassCorum

  class StatementPdf < ::StatementPdf

    include TextHelpers::Translation
    def translation_scope
      "umass_corum.statement_pdf"
    end

    # Mark all the input as html_safe so that text_helpers doesn't escape quotes or
    # other special characters. And don't smartify it because rails will turn a quote
    # into a curly quote entity which Prawn then displays as is (&rquo;).
    def text(key, options = {})
      html_safe_options = options.transform_values { |k| k.respond_to?(:html_safe) ? k.html_safe : k }
      super(key, html_safe_options.with_defaults(smart: false))
    end

    attr_reader :pdf, :statement
    delegate :facility, to: :statement

    def options
      super.merge(
        left_margin: 0.25.in,
        right_margin: 0.25.in,
        bottom_margin: 0.5.in,
        top_margin: 0.5.in,
      )
    end

    CELL_STYLE = { border_width: 1, padding: 4 }.freeze
    MAIN_FONT_SIZE = 9 # Points

    def generate(pdf)
      @pdf = pdf
      pdf.default_leading = 2.5 # Points

      draw_header
      draw_bill_to_and_remit
      draw_po_and_terms
      draw_order_details_table
      draw_footer
    end

    private

    def draw_header
      # Use inches when dealing with graphics
      pdf.move_up(0.2.in)
      pdf.image("#{UmassCorum::Engine.root}/app/assets/images/umass_corum/umass-ials-logo.jpg", height: 0.7.in)
      pdf.move_up(0.2.in)
      pdf.font_size(20) { pdf.text(text("invoice_header"), align: :right, style: :bold) }

      pdf.move_down(MAIN_FONT_SIZE)
      same_row(
        method(:draw_address),
        method(:draw_date_and_invoice_number)
      )
      pdf.move_down(8)
    end

    def draw_address
      pdf.font_size(11) do
        pdf.text text("header_address", facility: facility.name, address: facility.address), leading: 1.5
      end
    end

    def draw_date_and_invoice_number
      data = [
        [text("date_header"), Statement.human_attribute_name(:id)],
        [format_usa_date(@statement.created_at), @statement.invoice_number],
      ]
      pdf.font_size(MAIN_FONT_SIZE)
      pdf.table(
        data,
        header: true,
        cell_style: CELL_STYLE.merge(align: :center),
        position: :right,
        width: grid(4),
      )
    end

    def draw_bill_to_and_remit
      same_row(
        method(:draw_bill_to_box),
        method(:draw_remit_box),
      )
      pdf.move_down(16)
    end

    def draw_bill_to_box
      data = [
        [text("bill_to_header")],
        [normalize_whitespace(@account.remittance_information) || "\n\n\n\n"],
      ]
      pdf.table(data,
        cell_style: CELL_STYLE,
        width: grid(5),
      )
    end

    def draw_remit_box
      data = [
        [text("remit_box", address: @statement.facility.address)],
      ]

      pdf.table(data,
        cell_style: CELL_STYLE.merge(align: :center),
        position: :right,
        width: grid(5),
      )
    end

    def draw_po_and_terms
      po_number = @account.type == "PurchaseOrderAccount" ? @account.account_number : "\n"
      data = [
        [text("po_number_header"), text("terms_header")],
        [po_number, text("terms_text")],
      ]
      pdf.table(
        data,
        header: true,
        cell_style: CELL_STYLE.merge(align: :center),
        position: :right,
        width: grid(4),
      )
    end

    def draw_order_details_table
      data = [order_detail_headers] +
        order_detail_rows +
        [[{ content: pay_by_card, colspan: 5, inline_format: true }, { content: text("total", total: number_to_currency(total_due)), colspan: 2 }]]

      description_width = grid(4)
      other_width = grid((12 - 4).to_f / 6)
      pdf.table(
        data,
        width: pdf.bounds.width,
        cell_style: CELL_STYLE.merge(borders: [:left, :right]),
        header: true,
        column_widths: [other_width, other_width, other_width, description_width, other_width, other_width, other_width],
      ) do
        column([0, 5, 6]).style(align: :right)
        row(0).style(borders: [:top, :bottom, :left, :right], align: :center)
        row(-2).style(borders: [:bottom, :left, :right])
        row(-1).style(borders: [:bottom, :left, :right])
        row(-1).column(0).style(align: :center, font_style: :bold)
        row(-1).column(-2).style(size: 14, font_style: :bold)
      end
    end

    def draw_footer
      # Start a new page if the the second row would get orphaned on its own page
      pdf.start_new_page if pdf.cursor < 36
      data = [
        [
          text("footer_headers.phone"),
          text("footer_headers.fax"),
          text("footer_headers.email"),
          text("footer_headers.website"),
        ],
        [facility.phone_number, facility.fax_number, facility.email, { content: html("contact_url", inline: true), inline_format: true }]
      ]
      pdf.table(
        data,
        width: grid(10),
        position: :center,
        cell_style: CELL_STYLE.merge(align: :center),
      )
    end

    def order_detail_headers
      [
        text("order_detail_headers.quantity"),
        text("order_detail_headers.date"),
        text("order_detail_headers.order_number"),
        text("order_detail_headers.description"),
        text("order_detail_headers.unit_of_measure"),
        text("order_detail_headers.rate"),
        text("order_detail_headers.amount"),
      ]
    end

    def order_detail_rows
      order_details.map do |order_detail|
        [
          order_detail_quantity(order_detail),
          format_usa_date(order_detail.ordered_at),
          order_detail.to_s,
          [order_detail.product, normalize_whitespace(order_detail.note)].map(&:presence).compact.join("\n"),
          order_detail.product.quantity_as_time? ? "hr" : "",
          number_to_currency(order_detail.actual_cost / order_detail.quantity),
          number_to_currency(order_detail.actual_total),
        ]
      end
    end

    def pay_by_card
      html("pay_by_card", url: facility.payment_url, inline: true) if facility.payment_url.present?
    end

    def order_details
      @statement
        .order_details
        .includes(:product, order: :user)
        .order(fulfilled_at: :desc)
    end

    def total_due
      order_details.map(&:actual_total).sum
    end

    # Run a series of procs that will all draw to the same row. At the end, move
    # the cursor to the bottom of the tallest one.
    def same_row(*blocks)
      top = pdf.cursor
      bottoms = Array(blocks).map do |block|
        block.call
        bottom = pdf.cursor
        pdf.move_cursor_to(top)
        bottom
      end

      pdf.move_cursor_to(bottoms.min)
    end

    # Use a 12-column grid. To get half the page, you can use grid(6). For a quarter, grid(3).
    def grid(columns)
      pdf.bounds.width * columns / 12
    end

    def order_detail_quantity(order_detail)
      if order_detail.time_data.present? && order_detail.time_data.respond_to?(:billable_minutes)
        minutes = order_detail.time_data.billable_minutes
        QuantityPresenter.new(order_detail.product, minutes).to_s if minutes
      else
        QuantityPresenter.new(order_detail.product, order_detail.quantity).to_s
      end
    end
  end

end
