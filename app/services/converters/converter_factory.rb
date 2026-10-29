# frozen_string_literal: true

module Converters
  class ConverterFactory
    def self.for(converter_type)
      new.for(converter_type)
    end

    def for(converter_type)
      Settings.converters[converter_type].constantize
    end
  end
end
