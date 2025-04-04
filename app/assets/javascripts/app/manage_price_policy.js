/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
(function() {
  const Cls = (window.RateWatcher = class RateWatcher {
    static initClass() {
      this.rateClass = '.usage_rate';
      this.adjustClass = '.usage_adjustment';
    }


    constructor() {
      this.masterClass = '.master_usage_cost';
      this.rateClass = this.constructor.rateClass;
      this.adjustClass = this.constructor.adjustClass;
      this.setupRates();
      this.setupAdjustments();
    }


    setupRates() {
      $(this.rateClass).each((i, elem)=> this.showRatePerMinute($(elem)));
      return $(this.rateClass).bind('keyup', e=> this.showRatePerMinute($(e.target)));
    }


    updateAdjustments() {
      return $(this.adjustClass).each((i, elem)=> this.showAdjustmentPerMinute($(elem)));
    }


    setupAdjustments() {
      this.updateAdjustments();
      $(this.adjustClass).bind('keyup', e=> this.showAdjustmentPerMinute($(e.target)));
      return $(this.masterClass).bind('keyup', () => this.updateAdjustments());
    }


    showRatePerMinute($input){
      return this.displayRate($input, $input.val() / 60);
    }


    showAdjustmentPerMinute($input){
      const masterVal = $(this.masterClass).val();
      return this.displayRate($input, (masterVal - $input.val()) / 60);
    }


    hasValue($input){
      return $input.is(':not(:disabled)') && ($input.val() > 0);
    }


    displayRate($input, rate){
      $input.next('.per-minute').remove();
      if (this.hasValue($input)) { return $input.after(`<p class=\"per-minute\">$${rate.toFixed(4)} / minute</p>`); }
    }
  });
  Cls.initClass();
})();

$(function() {
  const target = `${RateWatcher.rateClass},${RateWatcher.adjustClass}`;
  if ($(target).length) { return new RateWatcher(); }
});

