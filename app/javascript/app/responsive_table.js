/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.ResponsiveTable = class ResponsiveTable {

  static respond() {
    if (!window.IS_RESPONSIVE) { return; }
    return $(".js--responsive_table").each((index, table) => new ResponsiveTable($(table)).make_responsive());
  }

  constructor(table) {
    this.table = table;
  }

  make_responsive() {
    this.fill_empty_cells();
    return this.add_responsive_headers();
  }

  fill_empty_cells() {
    return this.table.find("td").each((index, cell) => {
      const empty = $(cell).text().trim().length === 0;
      if (empty) { return $(cell).append("&nbsp;"); }
    });
  }

  add_responsive_headers() {
    return this.table.find("tbody tr").each((index, row) => this.add_header_to_row($(row)));
  }

  add_header_to_row($row) {
    // Only get the immediate child cells of the row. Without the `>`, it could
    // also find cells in nested tables.
    const cells = $row.find("> td");
    return cells.prepend(index => this.responsive_header($row, index));
  }

  responsive_header($row, index) {
    return $("<div>").addClass("responsive-header").text(this.text_for_header($row, index));
  }

  text_for_header($row, index) {
    const header = $($row.closest("table").find("thead th").eq(index));
    return header.data("mobile-header") || header.text();
  }
};

$(() => ResponsiveTable.respond());
