$(function() {
  //Tool Tip
  tooltipContent = function($el, $tip) {
    var match = $el.attr("id").match(/block_(\w+_)?reservation_(\d+)/);
    var prefix = match[1] || "";
    var id = match[2];
    return $("#tooltip_" + prefix + "reservation_" + id).html();
  }

  $('.tip').tooltipsy({
      content: tooltipContent,
      hide: function (e, $el) {
             $el.delay(500),
             $el.fadeOut(10)
         }
  });

  // Date select calendar
  $(".datepicker").datepicker({
    showOn: "button",
    buttonText: "<i class='fa fa-calendar icon-large'>",
  }).change(function() {
    var form = $(this).parents('form');
    var formUrl = form.attr('action');
    form.attr('action', formUrl + '#' + lastHiddenInstrumentId());
    form.submit();
  });

  //Get the Current Hour, create a class and add it the time div
  time = function() {
    $e = $('.current_time');
    var currentTime = new Date();
    // minutes since midnight
    var minutes = currentTime.getHours() * 60 + currentTime.getMinutes();
    // Cache the pixel to minute ratio based on where it's initially displayed
    if (!window.PIXEL_TO_MINUTE_RATIO) {
      var pixels = parseInt($e.css('left'));
      window.PIXEL_TO_MINUTE_RATIO = (pixels / minutes).toFixed(2);
    }
    var pixels = Math.floor(minutes * PIXEL_TO_MINUTE_RATIO) + 'px'
    $e.css('left', pixels);
  };
  time();
  setInterval(time, 30000);

  showOrHideCanceled = function() {
    if ($('#show_canceled').is(':checked')) {
      $('.status_canceled').fadeIn('fast');
    } else {
      $('.status_canceled').fadeOut('fast');
    }

  }
  $('#show_canceled').change(showOrHideCanceled);
  // no animation when first loading
  $('.status_canceled').toggle($('#show_canceled').is(':checked'));

  relayCheckboxes = $('.relay_checkbox :checkbox')
  if (relayCheckboxes.length > 0) {
    relayCheckboxes.bind('click', function(e) {
      if (confirm("Are you sure you want to toggle the relay?")) {
        $(this).parent().addClass("loading");
        $.ajax({
          url: $(this).data("relay-url"),
          success: function(data) {
            updateRelayStatus(data.instrument_status);
          },
          data: {
            switch: $(this).is(":checked") ? "on" : "off"
          },
          dataType: 'json'
        });
      } else {
        return false;
      }
    })
    .toggleSwitch();
  }

  function loadRelayStatuses() {
    $.ajax({
      url: '../instrument_statuses',
      success: function(data) {
        for(var i = 0; i < data.length; i++) {
          updateRelayStatus(data[i].instrument_status);

        }
        // Refresh 2 minutes after updating
        setTimeout(loadRelayStatuses, 120000);
      },
      dataType: 'json'
    });
  }

  function updateRelayStatus(stat) {
    $checkbox = $("#relay_" + stat.instrument_id);
    // remove pre-existing errors
    $checkbox.parent().find("span.error").remove();
    if (stat.error_message) {
      $checkbox.prop("disabled", true);
      // add a new error if there is one
      $checkbox.parent().append($("<span class=\"error\" title=\"" + stat.error_message + "\"></span>"));
    } else {
      $checkbox.prop("disabled", false).prop("checked", stat.is_on);
    }
    $checkbox.parent().removeClass("loading");
    $checkbox.trigger("change");
  }

  $('.relay_checkbox').addClass('loading');
  // Only try to load relay statuses if there are relays to check
  if ($('.relay_checkbox :checkbox').length > 0) loadRelayStatuses();

  function lastHiddenInstrumentId() {
    var hiddenInstruments = $('.timeline_instrument').filter(function() {
      return $(window).scrollTop() + $('.timeline_header').height() > $(this).offset().top;
    });

    return hiddenInstruments.last().attr('id');
  }

  $('#reservation_left, #reservation_right').on('click', function(event) {
    var urlWithoutFragment = this.href.split('#')[0]
    this.href = urlWithoutFragment + '#' + lastHiddenInstrumentId()
  });
});
