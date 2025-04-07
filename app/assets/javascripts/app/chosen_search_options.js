$(function () {
  const csrfTokenElement = document.querySelector('meta[name="csrf-token"]');

  if (!csrfTokenElement) return;

  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

  let selectField = $(".js--chosen.js--select-with-search");

  if (!selectField) return;

  const searchUrl = selectField.data("searchUrl");

  if (!searchUrl) return;

  const searchInput = selectField
    .next(".chosen-container")
    .find(".chosen-search input");

  let searchTimeout;

  searchInput.on('input', function() {
    const query = this.value.trim();

    clearTimeout(searchTimeout);

    if (query.length < 3) return;

    searchTimeout = setTimeout(function() {
      fetch(`${searchUrl}?query=${query}`, {
        headers: {
          "X-CSRF-Token": csrfToken,
          Accept: "application/json",
        },
      })
        .then((response) => response.json())
        .then((data) => {
          selectField.empty();
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
