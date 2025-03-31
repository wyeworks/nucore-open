/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe("TimeFormatter", function() {

  describe('fromString', function() {
    describe('date parsing', function() {
      beforeEach(function() {
        return this.formatter = new TimeFormatter.fromString('4/17/2015', '3', '15', 'AM');
      });

      it('has the correct year', function() {
        return expect(this.formatter.year()).toEqual(2015);
      });

      it('has the correct month', function() {
        expect(this.formatter.month()).toEqual(4);
        return expect(this.formatter.toString()).toContain('Apr');
      });

      it('has the correct day', function() {
        return expect(this.formatter.day()).toEqual(17);
      });

      return it('has the correctly formatted date', function() {
        return expect(this.formatter.dateString()).toEqual('4/17/2015');
      });
    });

    return describe('time parsing', function() {
      it('sets the right time for an AM', function() {
        const formatter = new TimeFormatter.fromString('6/13/2015', '3', '15', 'AM');
        expect(formatter.hour24()).toEqual(3);
        return expect(formatter.minute()).toEqual(15);
      });

      it('sets the right time for PM', function() {
        const formatter = new TimeFormatter.fromString('6/13/2015', '3', '15', 'PM');
        expect(formatter.hour24()).toEqual(15);
        return expect(formatter.minute()).toEqual(15);
      });

      it('sets the right hour for midnight', function() {
        const formatter = new TimeFormatter.fromString('6/13/2015', '12', '00', 'AM');
        return expect(formatter.hour24()).toEqual(0);
      });

      return it('sets the right hour for noon', function() {
        const formatter = new TimeFormatter.fromString('6/13/2015', '12', '00', 'PM');
        return expect(formatter.hour24()).toEqual(12);
      });
    });
  });

  return describe('from a Date', function() {
    it('has the right month', function() {
      const date = new Date(2015, 3, 12, 3, 15);
      const formatter = new TimeFormatter(date);
      expect(formatter.month()).toEqual(4);
      expect(date.toString()).toContain('Apr');
      return expect(formatter.toString()).toContain('Apr');
    });

    it('gives the right formatted date', function() {
      const date = new Date(2015, 3, 12, 3, 15);
      const formatter = new TimeFormatter(date);
      return expect(formatter.dateString()).toEqual('4/12/2015');
    });

    it('gives the right thing for an AM', function() {
      const date = new Date(2015, 3, 12, 3, 15);
      const formatter = new TimeFormatter(date);
      expect(formatter.hour12()).toEqual(3);
      return expect(formatter.meridian()).toEqual('AM');
    });

    it('gives the right thing for a PM', function() {
      const date = new Date(2015, 3, 12, 15, 15);
      const formatter = new TimeFormatter(date);
      expect(formatter.hour12()).toEqual(3);
      return expect(formatter.meridian()).toEqual('PM');
    });

    it('gives the right thing for midnight', function() {
      const date = new Date(2015, 3, 12, 0, 15);
      const formatter = new TimeFormatter(date);
      expect(formatter.hour12()).toEqual(12);
      return expect(formatter.meridian()).toEqual('AM');
    });

    return it('gives the right thing for noon', function() {
      const date = new Date(2015, 3, 12, 12, 15);
      const formatter = new TimeFormatter(date);
      expect(formatter.hour12()).toEqual(12);
      return expect(formatter.meridian()).toEqual('PM');
    });
  });
});
