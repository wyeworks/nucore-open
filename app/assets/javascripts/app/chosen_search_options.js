const forceChosenInput = (select, data, query) => {
  if (!select || !data || data.length) return;

  const optionText = query
    ? `No results found for: ${query}`
    : "No results found";
  select.append(
    `<option value="" class="no-results-option"> ${optionText} </option>`
  );

  select.trigger("chosen:updated");
};

const csrfToken = () => {
  const csrfTokenElement = document.querySelector('meta[name="csrf-token"]');

  if (!csrfTokenElement) return "";

  return csrfTokenElement.content;
};

$(function () {
  let selectField = $(".js--chosen.js--select-with-search");

  if (!selectField) return;

  const searchUrl = selectField.data("searchUrl");

  if (!searchUrl) return;

  const chosenContainer = selectField.next(".chosen-container");
  const searchInput = chosenContainer.find(".chosen-search input");

  forceChosenInput(selectField, [], "");

  let searchTimeout;

  searchInput.on("input", function () {
    const query = this.value.trim();

    clearTimeout(searchTimeout);

    if (query.length < 3) return;

    searchTimeout = setTimeout(function () {
      fetch(`${searchUrl}?query=${query}`, {
        headers: {
          "X-CSRF-Token": csrfToken(),
          Accept: "application/json",
        },
      })
        .then((response) => response.json())
        .then((data) => {
          selectField.empty();

          if (!data.length) {
            forceChosenInput(usersField, data, query);
          }

          data.forEach(function (option) {
            return selectField.append(
              '<option value="' + option.id + '">' + option.name + "</option>"
            );
          });

          selectField.trigger("chosen:updated");
          selectField.next(".chosen-container").trigger("mousedown");

          searchInput.val(query);
        })
        .catch((error) => {
          console.error("Error fetching options:", error);
        });
    }, 600);
  });
});
