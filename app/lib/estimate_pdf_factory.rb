# frozen_string_literal: true

class EstimatePdfFactory
  def self.build(...)
    klass.new(...)
  end

  def self.defined?
    klass.present?
  end

  private_class_method def self.klass
    Settings.dig(:estimate_pdf, :class_name)&.constantize
  end
end
