/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.TimeFormatter = class TimeFormatter {
  constructor(dateTime) {
    this.dateTime = dateTime;
  }

  hour12() {
    let hour = this.hour24() % 12;
    if (hour === 0) { hour = 12; }
    return hour;
  }

  hour24() {
    return this.dateTime.getHours();
  }

  minute() {
    return this.dateTime.getMinutes();
  }

  meridian() {
    if (this.hour24() < 12) { return 'AM'; } else { return 'PM'; }
  }

  year() {
    return this.dateTime.getFullYear();
  }

  // getMonth() returns 0-11, we want to return the more natural 1-12
  month() {
    return this.dateTime.getMonth() + 1;
  }

  day() {
    return this.dateTime.getDate();
  }

  dateString() {
    return this.dateTime.toString("M/d/yyyy");
  }

  toString() {
    return this.dateTime.toString();
  }

  toDateTime() {
    return this.dateTime;
  }

  static fromString(date, hour, minute, meridian) {
    let parsedHour = parseInt(hour, 10) % 12;
    if (meridian === "PM") { parsedHour += 12; }

    const parsedMinute = parseInt(minute, 10);

    const split = date.split("/");

    // Date uses 0-11 for months
    const parsedMonth = parseInt(split[0], 10) - 1;
    const parsedDay = parseInt(split[1], 10);
    const parsedYear = parseInt(split[2], 10);

    date = new Date(parsedYear, parsedMonth, parsedDay, parsedHour, parsedMinute);
    return new TimeFormatter(date);
  }
};
