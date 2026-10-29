# frozen_string_literal: true

class MessageSummarizer::MessageSummary
  attr_reader :controller

  def initialize(controller)
    @controller = controller
  end

  def any?
    count > 0
  end

  def count
    @count ||= get_count
  end

  def link
    controller.view_context.link_to(label, path)
  end

  def visible?
    allowed? && in_context? && any?
  end

  private

  def in_context?
    raise NotImplementedError.new("Subclass must implement")
  end

  def allowed?
    raise NotImplementedError.new("Subclass must implement")
  end

  def get_count
    raise NotImplementedError.new("Subclass must implement")
  end

  def i18n_key
    raise NotImplementedError.new("Subclass must implement")
  end

  def path
    raise NotImplementedError.new("Subclass must implement")
  end

  def ability
    controller.current_ability
  end

  def label
    "#{I18n.t(i18n_key)} (#{count})"
  end
end
