/***
 * Triggers a full refresh of the page at a specified interval.
 *
 * Usage:
   = content_for :head_content do
     = javascript_include_tag "page_refresh"

   .js--pageRefresh{ data: { refresh_interval: 1.hour } }
***/

document.addEventListener("DOMContentLoaded", function() {
  const page = document.getElementsByClassName("js--pageRefresh")[0];
  const refreshInterval = page.dataset["refreshInterval"] || 60; // in seconds

  function refresh() {
    window.location.reload()
  }

  window.setInterval(refresh, refreshInterval * 1000);
});
