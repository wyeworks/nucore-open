// Used on the instrument manage page
$(function() {
  var power_relay_section = $('#power-relay')
    , instrument_control_mechanism = $('#instrument_control_mechanism');

  instrument_control_mechanism.change(function() {
    var selection = instrument_control_mechanism.val();

    if(selection == 'relay') {
        power_relay_section.show();
        power_relay_section.find(':input').removeAttr('disabled');
    } else {
        power_relay_section.hide();
        power_relay_section.find(':input').attr('disabled', 'disabled');
    }
  });

  instrument_control_mechanism.trigger('change');
});
