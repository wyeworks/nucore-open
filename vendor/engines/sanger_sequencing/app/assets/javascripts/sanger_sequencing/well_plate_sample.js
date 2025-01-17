/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Cls = (SangerSequencing.Sample = class Sample {
  static initClass() {
  
    this.Blank = class Blank {
      submissionId() {
        return "";
      }
      customerSampleId() {
        return "";
      }
      displayId() {
        return "";
      }
      id() {
        return "";
      }
    };
  
    // Treated as blank in the backend, but displays like reserved
    this.ReservedButUnused = class ReservedButUnused {
      submissionId() {
        return "";
      }
      customerSampleId() {
        return "reserved";
      }
      displayId() {
        return "";
      }
      id() {
        return "";
      }
    };
  
  
    this.Reserved = class Reserved {
      submissionId() {
        return "";
      }
      customerSampleId() {
        return "reserved";
      }
      displayId() {
        return "";
      }
      id() {
        return "reserved";
      }
    };
  }
  constructor(attributes) { this.attributes = attributes; undefined; }

  customerSampleId() {
    return this.attributes.customer_sample_id;
  }

  displayId() {
    return this.attributes.id;
  }

  submissionId() {
    return this.attributes.submission_id;
  }

  id() {
    return this.attributes.id;
  }
});
Cls.initClass();
