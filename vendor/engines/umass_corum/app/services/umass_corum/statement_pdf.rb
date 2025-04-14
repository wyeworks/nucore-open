# frozen_string_literal: true

# 1 inch = 72 points
# In general, we should use points when dealing with font-relational measurements,
# but we can use inches when dealing with graphics and page layout.
require "prawn/measurement_extensions"

module UmassCorum

  class StatementPdf < ::StatementPdf

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
      draw_payment_desc_and_terms
      draw_order_details_table
      draw_totals
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
      data = if @statement.display_cross_core_messsage?
               [
                 [text("cross_core_message")],
                 [text("remit_box", address: @statement.facility.address)],
               ]
             else
               [
                 [text("remit_box", address: @statement.facility.address)],
               ]
             end

      pdf.table(data,
                cell_style: CELL_STYLE.merge(align: :center),
                position: :right,
                width: grid(5),
               )
    end

    def draw_payment_desc_and_terms
      data = [
        [payment_type_header, text("terms_header")],
        [payment_description, text("terms_text")],
      ]
      pdf.table(
        data,
        header: true,
        cell_style: CELL_STYLE.merge(align: :center),
        position: :right,
        width: grid(4),
      )
    end

    def payment_description
      if @account.type == "PurchaseOrderAccount"
        @account.account_number
      elsif @account.type == "CreditCardAccount"
        @account.description
      elsif @account.respond_to?(:primary_payment_info)
        @account.primary_payment_info
      else
        "\n"
      end
    end

    def payment_type_header
      if @account.type == "CreditCardAccount" || @account.try(:cc_split?)
        text("cc_description_header")
      else
        text("po_number_header")
      end
    end

    def draw_order_details_table
      table_data = [order_detail_headers + order_detail_rows] + table_style_options
      pdf.table(*table_data) do
        column([0, 5, 6]).style(align: :right)
        row(-1).style(borders: [:bottom, :left, :right])
        row(0).style(borders: [:top, :bottom, :left, :right], align: :center)
      end
    end

    def draw_totals
      table_data = if @account.respond_to?(:mivp_percent)
                     [voucher_rows] + table_style_options
                   else
                     [actual_total_row] + table_style_options
                   end
      pdf.table(*table_data) do
        column([5, 6]).style(align: :right)
        row(-1).style(borders: [:bottom, :left, :right])
        column(0).style(align: :center, font_style: :bold)
        row(-1).column(-2).style(size: 14, font_style: :bold)
      end
    end

    def table_style_options
      description_width = grid(4)
      other_width = grid((12 - 4).to_f / 6)
      [
        width: pdf.bounds.width,
        cell_style: CELL_STYLE.merge(borders: [:left, :right]),
        header: true,
        column_widths: [other_width, other_width, other_width, description_width, other_width, other_width, other_width],
      ]
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
      pdf.move_down(20)
      pdf.text(html("survey_link", inline: true), align: :center, style: :bold, inline_format: true)
    end

    def order_detail_headers
      [
        [
          text("order_detail_headers.quantity"),
          text("order_detail_headers.date"),
          text("order_detail_headers.order_number"),
          text("order_detail_headers.description"),
          text("order_detail_headers.unit_of_measure"),
          text("order_detail_headers.rate"),
          text("order_detail_headers.amount"),
        ]
      ]
    end

    def order_detail_rows
      order_details.map { |order_detail| UmassCorum::OrderDetailStatementRowPresenter.new(order_detail).to_row }
    end

    def actual_total_row
      [[{ content: pay_by_card, colspan: 5, inline_format: true }, { content: actual_total_text, colspan: 2 }]]
    end

    # Each nested array represents a row
    # Each hash represents a cell, provide content, and colspan for cell size
    def voucher_rows
      total_due_text = text("total_due", total: number_to_currency(total_due))
      [[{ content: "\n", colspan: 5 }, { content: actual_total_text, colspan: 2 }]] +
        [[{ content: pay_by_card, colspan: 5, inline_format: true }, { content: mivp_percent_label, colspan: 2 }]] +
        [[{ content: "\n", colspan: 5 }, { content: total_due_text, colspan: 2 }]]
    end

    def pay_by_card
      html("pay_by_card", url: facility.payment_url, inline: true) if facility.payment_url.present?
    end

    def actual_total_text
      text("acutal_total", total: number_to_currency(actual_total_amount))
    end

    def mivp_percent_label
      percent = number_to_percentage(@account.mivp_split.percent, strip_insignificant_zeros: true)
      text("mivp_total", percent: percent, total: number_to_currency(mivp_total_amount))
    end

    def actual_total_amount
      order_details.map(&:actual_total).sum
    end

    def mivp_total_amount
      virtual_order_details.select { |od| od.account.type == "UmassCorum::VoucherAccount" }.map(&:actual_total).sum
    end

    def total_due
      actual_total_amount - mivp_total_amount
    end

    def virtual_order_details
      @virtual_order_details ||= Array(OrderDetailListTransformerFactory.instance(order_details).perform)
    end

    def order_details
      @statement
        .order_details
        .includes(:product, order: :user)
        .order(fulfilled_at: :desc)
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
  end

end
