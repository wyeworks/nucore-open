# frozen_string_literal: true

module TranslationHelper

  def t_manage_models(clazz)
    I18n.t("pages.manage", model: clazz.model_name.human(count: :many))
  end

  def t_create_model(clazz)
    I18n.t("pages.create", model: clazz.model_name.human)
  end

  def t_create_models(clazz)
    I18n.t("pages.create", model: clazz.model_name.human(count: :many))
  end

  def t_my(clazz)
    I18n.t("pages.my_tab", model: clazz.model_name.human(count: :many))
  end

  def t_model_error(clazz, error, *options)
    I18n.t("activerecord.errors.models.#{clazz.model_name.to_s.underscore}.#{error}", *options)
  end

  def t_boolean(value)
    I18n.t(value.to_s, scope: "boolean")
  end

end
