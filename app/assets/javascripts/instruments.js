$(document).ready(function() {
  const calendar = $("#calendar");
  const defaultView = calendar.data('defaultView');

  const header = { left: 'title', center: '', right: '' };

  if (defaultView != 'month') {
    header.right = 'prev,next today agendaDay,agendaWeek,month';
  }

  new FullCalendarConfig(
    calendar, { header }
  ).init();
});
