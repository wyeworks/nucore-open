window.FacilityOrderShow = class FacilityOrderShow {
  constructor($accordion) {
    this.$accordion = $accordion;
  }

  initAccordion() {
    if (!this.$accordion.length) {
      return;
    }

    this.$accordion.accordion({
      active: false,
      heightStyle: "content",
      collapsible: true,
    });
  }
};

$(function () {
  const facilityOrderShow = new FacilityOrderShow($("#accordion"));
  return facilityOrderShow.initAccordion();
});
