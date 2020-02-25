# frozen_string_literal: true

module Journals

  class JournalFormat

    attr_reader :key

    def self.find(key)
      all.find { |format| format.key == key }
    end

    def self.all
      Array(Settings.financial.journal_format).map { |options| new(**options) }
    end

    def self.exists?(key)
      find(key).present?
    end

    def initialize(key:, class_name: nil, mime_type: nil, filename: nil)
      @class_name = class_name
      @key = key
      @mime_type = mime_type
      @filename = filename
    end

    def render(journal)
      @class_name.constantize.new(journal).render
    end

    def options
      {
        mime_type: Mime[mime_type],
        filename: @filename || "journal.#{key}"
      }
    end

    def mime_type
      @mime_type || key
    end

  end

end
