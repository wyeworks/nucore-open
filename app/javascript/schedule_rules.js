$(document).ready(function() {
  $('#calendar').fullCalendar({
                  editable: false,
                  defaultView: 'agendaWeek',
                  allDaySlot: false,
                  header: {left: '', center: '', right: ''},
                  columnHeaderFormat: 'ddd',
                  events: events_path
                })
})
