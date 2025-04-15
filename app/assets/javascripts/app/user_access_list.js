/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(function() {

  const addCheckboxChangeHandler = function($row){
    const $checkbox = $row.find(":checkbox");
    const $select = $row.find("select");
    $checkbox.on("change", function() { return $select.prop({disabled: !this.checked}); });
    return $checkbox.change();
  };

  return $(".js--access-list-row").each(function() { return addCheckboxChangeHandler($(this)); });
});
