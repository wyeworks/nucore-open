module Formio
  class SubmissionsController < ApplicationController

    before_action :authenticate_user!

    layout "formio"

    def new
      @formio_url = params[:formio_url]
      @prefill_data = prefill_data
      @redirect_url = redirect_url
    end

    def show
      @formio_url = params[:formio_url]
    end

    def edit
      @formio_url = params[:formio_url]
      @redirect_url = redirect_url
    end

    private

    # NUcore’s SurveysController expects a referer param, which contains the page
    # to which NUcore should redirect after it processes a form submission. However,
    # the success_url that we get from UrlService does not include this param. Instead,
    # we get it as a separate pram, so we construct the full redirect_url here to
    # avoid changing having to change code for unrelated integrations
    def redirect_url
      referer_url = URI(params[:referer])
      URI(params[:success_url]).tap do |success_url|
        success_url_params = Rack::Utils.parse_query(success_url.query)
        success_url.query = success_url_params.merge(referer: referer_url.to_s).to_query
      end.to_s
    end

    def order_detail
      @order_detail ||= OrderDetail.find(params[:receiver_id])
    end

    def prefill_data
      {
        accountOwnerEmail: order_detail.account.owner_user.email,
        accountOwnerName: order_detail.account.owner_user.full_name,
        accountOwnerUsername: order_detail.account.owner_user.username,
        nucoreOrderNumber: order_detail.order_number,
        orderedAtDate: order_detail.created_at.to_date.to_s,
        orderedForEmail: order_detail.user.email,
        orderedForName: order_detail.user.full_name,
        orderedForUsernname: order_detail.user.username,
        paymentSourceAccountNumber: order_detail.account.account_number,
      }.merge(extra_prefill_data)
    end

    # Hook for university-specific forks to override this method and provide extra
    # data that doesn’t come from nucore-open
    def extra_prefill_data
      {}
    end

  end
end
