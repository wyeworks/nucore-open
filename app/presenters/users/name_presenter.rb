# frozen_string_literal: true

module Users
  class NamePresenter < SimpleDelegator
    def initialize(user, suspended_label: true, username_label: false)
      super(user)
      @suspended_label = suspended_label
      @username_label = username_label
    end

    def full_name
      render [first_name, last_name]
    end

    def last_first_name
      render [last_name, first_name].join(", ")
    end

    def render(name)
      parts = Array(name)
      parts << "(#{username})" if username_label?
      if suspended_label?
        if suspended?
          parts << "(#{user.class.human_attribute_name(:suspended)})"
        elsif expired?
          parts << "(#{user.class.human_attribute_name(:expired)})"
        end
      end
      parts.join(" ")
    end

    def user
      __getobj__
    end

    private

    def username_label?
      @username_label
    end

    def suspended_label?
      @suspended_label
    end
  end
end
