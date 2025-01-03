$(document).ready(function() {
  const calendar = $("#calendar");
  const defaultView = calendar.data('defaultView');

  const header = { left: 'title', center: '', right: '' };

  let defaultRightHeader = 'prev,next today';

  if (defaultView != 'month') {
    defaultRightHeader = `${defaultRightHeader} agendaDay,agendaWeek,month`;
  }

  header.right = defaultRightHeader;

  new FullCalendarConfig(
    calendar, { header }
  ).init();
});
