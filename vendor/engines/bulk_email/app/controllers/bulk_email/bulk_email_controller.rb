module BulkEmail

  class BulkEmailController < ApplicationController

    include CSVHelper

    admin_tab :all
    layout "two_column"

    before_action { @active_tab = "admin_users" }
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility
    before_action { authorize! :send_bulk_emails, current_facility }

    before_action :init_search_options, only: [:search]

    helper_method :datepicker_field_input
    helper_method :user_type_selected?

    def search
      @searcher = RecipientSearcher.new(@search_fields)
      @users = @searcher.do_search
    end

    def create
      @users = User.where_ids_in(params[:recipient_ids])
      @delivery_form = delivery_form # TK

      respond_to do |format|
        format.csv do
          filename = "bulk_email_recipients.csv"
          set_csv_headers(filename)
        end

        format.html
      end
    end

    def deliver
      delivery_form.assign_attributes(params)

      if delivery_form.valid?
        delivery_form.deliver_all!
        flash[:notice] = "TK delivered"
        redirect_to facility_bulk_email_path
      else
        @delivery_form = delivery_form
        @users = User.where_ids_in(delivery_form.recipient_ids)
        render :create
      end
    end

    private

    def delivery_form
      @delivery_form ||= DeliveryForm.new(current_facility)
    end

    def init_search_options
      @products = current_facility.products.active_plus_hidden.order("products.name").includes(:facility)
      @search_options = { products: @products }
      @search_fields = params.merge(facility_id: current_facility.id)
      @user_types = user_types
      @user_types.delete(:authorized_users) unless @products.exists?(requires_approval: true)
    end

    def datepicker_field_input(form, key)
      date = @search_fields[key].to_s.tr("-", "/")
      form.input(key, input_html: { value: date, class: :datepicker__data, name: key })
    end

    def user_types
      RecipientSearcher::USER_TYPES.each_with_object({}) do |user_type, hash|
        hash[user_type] = I18n.t("bulk_email.user_type.#{user_type}")
      end
    end

    def user_type_selected?(user_type)
      return false if params[:bulk_email].blank?
      params[:bulk_email][:user_types].include?(user_type.to_s)
    end

  end

end
