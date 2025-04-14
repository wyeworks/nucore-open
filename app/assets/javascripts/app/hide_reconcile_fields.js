document.addEventListener("DOMContentLoaded", function () {
  const RECONCILED = "reconciled";
  const UNRECOVERABLE = "unrecoverable";

  const formController = {
    form: document.querySelector(".js--reconcileForm"),
    orderStatus: document.querySelector(".js--orderStatusSelect"),
    bulkReconcileContainer: document.querySelector(".js--bulkReconcileFields"),
    reconcileDate: document.querySelector(".js--bulkReconcileDateField"),
    /**
     * Init form callbacks
     */
    init() {
      if (this.orderStatus) {
        this.initOrderStatusHandler();
      }

      if (this.form) {
        this.initFormHandler();
      }

    },
    initOrderStatusHandler() {
      this.orderStatus.addEventListener("change", (event) => {
        const selectedStatus = event.target.value;
        this.toggleStatusNoteFiled(selectedStatus);
        this.toggleReconcileDateField(selectedStatus === RECONCILED);
      });
    },
    initFormHandler() {
      this.form.addEventListener("submit", (_event) => {
        const selectedStatus = this.orderStatus.value;
        this.disableOtherNotesFields(selectedStatus);
      });
    },
    getStatusNoteFields(status) {
      return document.querySelectorAll(`.js--${status}Field`)
    },
    /**
     * Show note fields according to the selected status
     */
    toggleStatusNoteFiled(selectedStatus) {
      [RECONCILED, UNRECOVERABLE].forEach((status) => {
        this.getStatusNoteFields(status).forEach((element) => {
          if (selectedStatus === status) {
            element.classList.remove("hidden");
          } else {
            element.classList.add("hidden");
          } });
      })
    },
    /**
     * Show or hide reconcildeDate field
     */
    toggleReconcileDateField(show) {
      if (show) {
        this.reconcileDate.classList.remove("hidden");
      } else {
        this.reconcileDate.classList.add("hidden");
      }
    },
    /**
     * Disable other status' note fields so they are not submitted
     */
    disableOtherNotesFields(selectedStatus) {
      [RECONCILED, UNRECOVERABLE].forEach((status) => {
        this.getStatusNoteFields(status).forEach((element) => {
          const inputEl = element.querySelector("input");
          if (inputEl && status !== selectedStatus) {
            inputEl.disabled = true;
          }
        })
      })
    }
  };

  formController.init();
});
