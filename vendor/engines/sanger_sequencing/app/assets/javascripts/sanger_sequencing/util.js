/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
var exports = exports != null ? exports : this;
if (!exports.SangerSequencing) { exports.SangerSequencing = new Object; }

exports.SangerSequencing.Util = class Util {
  static flattenArray(arrays) {
    const concatFunction = (total, submission) => total.concat(submission);
    return arrays.reduce(concatFunction, []);
  }
};
