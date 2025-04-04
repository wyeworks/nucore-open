$(function () {
  const csrfTokenElement = document.querySelector('meta[name="csrf-token"]');

  if (!csrfTokenElement) return;

  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

  let usersField = $(".js--chosen.js--estimate-form");

  if (!usersField) return;

  const searchUrl = usersField.data("searchUrl");

  if (!searchUrl) return;

  const searchInput = usersField
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
          usersField.empty();
          data.forEach(function (user) {
            return usersField.append(
              '<option value="' + user.id + '">' + user.name + "</option>"
            );
          });

          usersField.trigger("chosen:updated");
          usersField.next(".chosen-container").trigger("mousedown");

          searchInput.val(query);
        })
        .catch((error) => {
          console.error("Error fetching users:", error);
        });
    }, 600);
  });
});
