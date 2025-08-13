/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

//= require helpers/jasmine-jquery

describe("Responsive table support", function() {

  beforeEach(function() {
    window.IS_RESPONSIVE = true;
    return loadFixtures("normal_table.html");
  });

  it("ignores a normal table", function() {
    ResponsiveTable.respond();
    return expect($(".table")).not.toContainElement(".responsive-header");
  });

  it("responds to a responsive table if reponsive", function() {
    $(".table").addClass("js--responsive_table");
    ResponsiveTable.respond();
    expect($("td .responsive-header").size()).toEqual(4);
    expect($("td .responsive-header").eq(0).text()).toEqual("Invoice #");
    expect($("td .responsive-header").eq(1).text()).toEqual("Facility");
    expect($("td .responsive-header").eq(2).text()).toEqual("Invoice #");
    return expect($("td .responsive-header").eq(3).text()).toEqual("Facility");
  });

  it("ignores a table if the global variable is false", function() {
    window.IS_RESPONSIVE = false;
    $(".table").addClass("js--responsive_table");
    ResponsiveTable.respond();
    return expect($(".table")).not.toContainElement(".responsive-header");
  });

  it("inserts a space if the table cell is empty, for spacing", function() {
    $(".table").addClass("js--responsive_table");
    const expected = $("td").eq(2).clone().append("Invoice #&nbsp;").text();
    ResponsiveTable.respond();
    expect($("td").eq(2).text()).toEqual(expected);
    return expect($("td").eq(3).text()).toEqual("FacilitySmall Hadron Collider");
  });

  return describe("when there is a sub-table", function() {
    beforeEach(function() {
      loadFixtures("nested_table.html");
      $(".table").addClass("js--responsive_table");
      return ResponsiveTable.respond();
    });

    it("sets the outer table headers", function() {
      const $outerTableHeaders = $("#outer-table > tbody > tr > td > .responsive-header");
      expect($outerTableHeaders.size()).toEqual(4);
      expect($outerTableHeaders.eq(0).text()).toEqual("Invoice #");
      expect($outerTableHeaders.eq(1).text()).toEqual("Facility");
      expect($outerTableHeaders.eq(2).text()).toEqual("Invoice #");
      return expect($outerTableHeaders.eq(3).text()).toEqual("Facility");
    });

    return it("sets the inner table headers", function() {
      const $innerTableHeaders = $("#inner-table .responsive-header");
      expect($innerTableHeaders.size()).toEqual(4);
      expect($innerTableHeaders.eq(0).text()).toEqual("Inner Header 1");
      expect($innerTableHeaders.eq(1).text()).toEqual("Inner Header 2");
      expect($innerTableHeaders.eq(2).text()).toEqual("Inner Header 1");
      return expect($innerTableHeaders.eq(3).text()).toEqual("Inner Header 2");
    });
  });
});
