document.addEventListener('DOMContentLoaded', () => {
  const userInput = document.querySelector('.js--user-autocomplete');
  if (!userInput) return;

  const userIdInput = document.getElementById(userInput.dataset.userInputId);

  if (!userInput || !userIdInput) {
    return;
  }

  $(userInput).autocomplete({
    minLength: 2,
    source: (request, response) => {
      $.getJSON(userInput.dataset.searchUrl, { query: request.term })
        .done(response)
        .fail((_error) => {
          response([]);
        });
    },
    select: (_event, ui) => {
      userInput.value = ui.item.name;
      userIdInput.value = ui.item.id;
      return false;
    }
  }).autocomplete('instance')._renderItem = (ul, item) => {
    return $('<li>')
      .append(`<div>${item.name}</div>`)
      .appendTo(ul);
  };
});
