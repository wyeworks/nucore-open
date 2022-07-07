# frozen_string_literal: true

module UmassCorum

  class UmassCorum::UserForm < ::UserForm

    include ActiveModel::Validations::Callbacks

    attr_reader :no_netid

    before_validation do
      self.username = email if @no_netid
    end

    def self.permitted_params
      super + [:no_netid, :phone_number, :subsidiary_account]
    end

    def assign_attributes(params)
      self.no_netid = params[:no_netid]
      super(params.except(:no_netid))
    end

    def no_netid=(value)
      @no_netid = ActiveModel::Type::Boolean.new.cast(value)
    end

    def admin_editable?
      true
    end

    def username_editable?
      !user.authenticated_locally?
    end

    def username_input_options
      {
        label: self.class.human_attribute_name(:netid),
        wrapper_html: { class: "js--username" }
      }
    end

    def form_head
      "umass_corum/users/form_head"
    end

    private

    def set_password
      # Only set the password if we're an external user
      super if @no_netid
    end

  end

end
