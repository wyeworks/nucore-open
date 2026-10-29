# frozen_string_literal: true

module ViewHookHelper
  # Look up the current path and render the view hooks for a specific placement
  def render_view_hook(placement, args = {})
    # Taken from translation helper shortcut (e.g. `t(".locale")`), this takes the
    # current view path, and converts slashes to dots, and the underscored partial as well
    # "facilities/manage" => "facilities.manage"
    # "facilities/_facility_fields" => "facilities.facility_fields"
    path = @virtual_path.gsub(%r{/_?}, ".")
    ViewHook.render_view_hook(path, placement, self, args)
  end

  def view_hook_exists?(placement)
    path = @virtual_path.gsub(%r{/_?}, ".")
    ViewHook.find(path, placement).any?
  end
end
