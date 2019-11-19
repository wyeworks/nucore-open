# frozen_string_literal: true

module UmassCorum

  class Engine < ::Rails::Engine

    isolate_namespace UmassCorum

    config.to_prepare do
      UsersController.user_form_class = UmassCorum::UserForm
      EngineManager.allow_view_overrides!("umass_corum")
    end

  end

end
