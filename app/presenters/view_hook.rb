# frozen_string_literal: true

class ViewHook

  class << self

    def instance
      @instance ||= new
    end

    delegate :add_hook, :remove_hook, :render_view_hook, :find, to: :instance

  end

  # Best used through `render_view_hook` helper method
  def render_view_hook(view, placement, context, args = {})
    find(view, placement).each_with_object("".html_safe) do |partial, buffer|
      buffer.safe_concat context.render(partial, **args)
    end
  end

  def add_hook(view, placement, partial)
    _view_hooks[view.to_s][placement.to_s] += [partial.to_s]
  end

  def remove_hook(view, placement, partial)
    _view_hooks[view.to_s][placement.to_s].delete partial.to_s
  end

  def find(view, placement)
    _view_hooks[view.to_s][placement.to_s]
  end

  private

  def _view_hooks
    @view_hooks ||= Hash.new { |h, k| h[k] = Hash.new([]) }
  end

end
