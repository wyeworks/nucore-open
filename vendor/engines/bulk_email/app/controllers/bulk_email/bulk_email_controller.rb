# frozen_string_literal: true

module BulkEmail

  class BulkEmailController < ApplicationController

    include CSVHelper

    admin_tab :all
    layout "two_column"

    before_action { @active_tab = "admin_users" }
    before_action :check_acting_as
    before_action :init_current_facility
    before_action :init_delivery_form, only: [:create, :deliver]
    before_action { authorize! :send_bulk_emails, current_facility }

    before_action :init_search_options, only: [:search]

    helper_method :bulk_email_content_generator
    helper_method :datepicker_field_input
    helper_method :user_type_selected?

    def search
      @searcher = RecipientSearcher.new(current_facility, @search_fields)
      @users = @searcher.do_search
    end

    def create
      @users = User.where_ids_in(params[:recipient_ids])

      respond_to do |format|
        format.csv do
          filename = "bulk_email_recipients.csv"
          set_csv_headers(filename)
        end

        format.html
      end
    end

    def deliver
      if @delivery_form.deliver_all
        flash[:notice] = text("bulk_email.delivery.success", count: @delivery_form.recipient_ids.count)
        redirect_to delivery_success_path
      else
        flash.now[:error] = text("bulk_email.delivery.failure")
        @users = User.where_ids_in(@delivery_form.recipient_ids)
        populate_flow_state_params
        render :create
      end
    end

    private

    # There are several hidden parameters in the bulk email compose form that
    # hold state on how the user got here, what product(s) the mail is about,
    # and how the recipients were chosen. If there is a form error, these params
    # need to be set to keep that state in the redisplayed form.
    def populate_flow_state_params
      return if params[:bulk_email_delivery_form].blank?
      search_criteria = JSON.parse(params[:bulk_email_delivery_form][:search_criteria])
      params.merge!(search_criteria.slice("bulk_email", "start_date", "end_date", "products", "facilities"))
      params.merge!(params[:bulk_email_delivery_form].permit(:product_id, :recipient_ids))
    end

    def bulk_email_cancel_path
      if cancel_params.present?
        facility_bulk_email_path(cancel_params)
      else
        facility_bulk_email_path
      end
    end

    def subject_product
      product_id = params[:product_id].presence ||
                   params[:bulk_email_delivery_form].try(:[], :product_id)
      Product.find(product_id) if product_id.present?
    end

    def bulk_email_content_generator
      @bulk_email_content_generator ||=
        ContentGenerator.new(current_facility, subject_product)
    end

    def delivery_success_path
      return_path_from_params || facility_bulk_email_path
    end

    def return_path_from_params
      # This controller accepts an optional return_path param to redirect to
      # after a successful mail queueup. This returns that param value if it is
      # a valid application path, or nil if not.
      return_path = params[:return_path].presence
      return_path if return_path &&
                     return_path.starts_with?("/") &&
                     Rails.application.routes.recognize_path(return_path)
    rescue ActionController::RoutingError
      nil
    end

    def init_delivery_form
      @delivery_form = DeliveryForm.new(current_user, current_facility, bulk_email_content_generator)
      @delivery_form.assign_attributes(params[:bulk_email_delivery_form])
    end

    def init_search_options
      products = Product.for_facility(current_facility).not_archived.alphabetized.includes(:facility)
      facilities = Facility.active.alphabetized if current_facility.cross_facility?
      @search_options = { products: products, facilities: facilities }
      @search_fields = params
      @user_types = user_types
      @user_types.delete(:authorized_users) unless products.exists?(requires_approval: true)
    end

    def datepicker_field_input(form, key)
      date = @search_fields[key].to_s.tr("-", "/")
      form.input(key, input_html: { value: date, class: :datepicker__data, name: key })
    end

    def user_types
      RecipientSearcher.user_types.each_with_object({}) do |user_type, hash|
        hash[user_type] = I18n.t("bulk_email.user_type.#{user_type}")
      end
    end

    def user_type_selected?(user_type)
      return false if params[:bulk_email].blank?
      params[:bulk_email][:user_types].include?(user_type.to_s)
    end

  end

end
