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
            for (let i = 0; i < data.length; i++) {
              updateRelayStatus(data[i].instrument_status);
            }
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
      },
      dataType: 'json'
    });
  }

  function updateRelayStatus(stat) {
    var $checkbox = $("#relay_" + stat.instrument_id);
    var $refreshBtn = $(".relay_refresh_btn[data-instrument-id='" + stat.instrument_id + "']");

    // remove pre-existing errors
    $checkbox.parent().find("span.error").remove();
    if (stat.error_message) {
      $checkbox.prop("disabled", true);
      // add a new error if there is one
      $checkbox.parent().append($("<span class=\"error\" title=\"" + stat.error_message + "\"></span>"));
    } else if (stat.is_on === null) {
      // No cached status - disable checkbox until status is refreshed
      $checkbox.prop("disabled", true);
    } else {
      $checkbox.prop("disabled", false).prop("checked", stat.is_on);
    }
    $checkbox.parent().removeClass("loading");
    $checkbox.trigger("change");

    // Update the refresh button's timestamp
    if (stat.updated_at) {
      var updatedAt = new Date(stat.updated_at);
      $refreshBtn.find('.relay_updated_at').text(formatRelativeTime(updatedAt));
    } else {
      $refreshBtn.find('.relay_updated_at').text('Never');
    }
    $refreshBtn.removeClass("loading").prop("disabled", false);
  }

  function formatRelativeTime(date) {
    var now = new Date();
    var diffMs = now - date;
    var diffMins = Math.floor(diffMs / 60000);
    var diffHours = Math.floor(diffMs / 3600000);
    var diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'just now';
    if (diffMins < 60) return diffMins + 'm ago';
    if (diffHours < 24) return diffHours + 'h ago';
    return diffDays + 'd ago';
  }

  // Handle individual refresh button clicks
  $('.relay_refresh_btn').on('click', function(e) {
    e.preventDefault();
    var $btn = $(this);
    var instrumentId = $btn.data('instrument-id');
    var $checkbox = $("#relay_" + instrumentId);

    $btn.addClass("loading").prop("disabled", true);
    $checkbox.parent().addClass("loading");

    $.ajax({
      url: '../instrument_statuses',
      data: {
        refresh: 'true',
        'instrument_ids[]': instrumentId
      },
      success: function(data) {
        if (data.length > 0) {
          updateRelayStatus(data[0].instrument_status);
        }
      },
      error: function(xhr) {
        $btn.removeClass("loading").prop("disabled", false);
        $checkbox.parent().removeClass("loading");
      },
      dataType: 'json'
    });
  });

  // Handle "Refresh All" button click
  $('#refresh_all_relays').on('click', function(e) {
    e.preventDefault();
    var $btn = $(this);

    $btn.addClass("loading").prop("disabled", true);
    $btn.find('.fa-refresh').addClass("fa-spin");

    $('.relay_checkbox').addClass("loading");
    $('.relay_refresh_btn').addClass("loading").prop("disabled", true);

    $.ajax({
      url: '../instrument_statuses',
      data: { refresh: 'true' },
      success: function(data) {
        for (var i = 0; i < data.length; i++) {
          updateRelayStatus(data[i].instrument_status);
        }
        $btn.removeClass("loading").prop("disabled", false);
        $btn.find('.fa-refresh').removeClass("fa-spin");
      },
      error: function(xhr) {
        $btn.removeClass("loading").prop("disabled", false);
        $btn.find('.fa-refresh').removeClass("fa-spin");
        $('.relay_checkbox').removeClass("loading");
        $('.relay_refresh_btn').removeClass("loading").prop("disabled", false);
      },
      dataType: 'json'
    });
  });

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
