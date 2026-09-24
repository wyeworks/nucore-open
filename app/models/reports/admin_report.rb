# frozen_string_literal: true

module Reports

  class AdminReport

    def self.all
      Array(Settings.admin_reports).map { |class_name| new(class_name) }
    end

    def self.find(key)
      all.find { |report| report.key == key }
    end

    def initialize(class_name)
      @class_name = class_name
    end

    def key
      @class_name.demodulize.underscore.delete_suffix("_report")
    end

    def report_class
      @class_name.constantize
    end

  end

end
