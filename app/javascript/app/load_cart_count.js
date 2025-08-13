function loadCartCount(cart) {
  const cartElement = document.querySelector(cart);

  if (!cartElement) { return; }

  let url = cartElement.dataset["url"];

  if (!url) { return; }

  url = new URL(url);

  fetch(url,).then(function (response) {
    if (response.ok) {
      response.text().then(function (data) {
        data = JSON.parse(data);
        const count = data.data.count;
        const text = `Cart (${count})`;

        cartElement.innerHTML = text;
      });
    } else {
      console.error("There was an error fetching the cart order details count");
    }
  });
}

document.addEventListener("DOMContentLoaded", function () {
  return loadCartCount(".js--cart_count");
});
