/***
 * This is used for public/semi-public dashboards that might be displayed on a
 * monitor onsite. By default it requests the same URL it is already on and replaces
 * the content inside the div with the result. We do this rather than a full refresh
 * in order to avoid a flash, which would happen if the full page refreshed.
 * The controller should only return the partial that needs to be refreshed rather
 * than the full layout.
 *
 * See the SecureRooms::Occupancies#index for an example.
***/
document.addEventListener("DOMContentLoaded", function() {
  const dashboard = document.getElementsByClassName("js--dashboardRefresh")[0];

  function fetchAndRefresh() {
    const url = new URL(dashboard.dataset["url"] || document.location);
    url.searchParams.set("refresh", "true");
    const headers = { Accept: "text/html" };

    fetch(url, { headers: headers })
    .then(function (response) {
      if (response.ok) {
        response.text()
        .then(function(body) {
          dashboard.innerHTML = body;
         });
      }
    });
  }

  if (dashboard) {
    // In seconds
    const refreshInterval = dashboard.dataset["refreshInterval"] || 5;
    window.setInterval(fetchAndRefresh, refreshInterval * 1000);
  }
});
