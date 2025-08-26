
$(function () {
  var oldText = $(".all_header").text();

  function removeExtraClasses(classlist) {
    classes = classlist.split(" ");
    if (classes.includes("all")) return "all";
    else if (classes.includes("recent")) return "recent";
    var identifier = classes.filter(function (element) {
      return element.startsWith("js--azlist")
    })
    return identifier[0];
  }

  $(document).on("click", ".js--az_listing", function () {
    $(".js--facility_listing").hide();
    var category = removeExtraClasses($(this).attr("class"));
    switch (category) {
      case "recent":
        $(".recent").show();
        break;
      case "all":
        $(".all_header").text(oldText);
        $(".js--facility_listing").show();
        break;
      default:
        $("." + category).show();
        $(".all_header").show();
        $(".all_header").text($(this).text());
    }
  });
});
