class TrainingRequestsController < ApplicationController
  admin_tab :index

  before_filter :authenticate_user!
  before_filter :check_acting_as

  load_and_authorize_resource

  layout "two_column"

  # GET /facilities/:facility_id/products/:product_id/training_requests/new
  def new
    load_product
  end

  # POST /facilities/:facility_id/products/:product_id/training_requests
  def create
    load_product
    if TrainingRequest.create(user: current_user, product: @product)
      flash[:notice] = t("training_requests.create.success", product: @product)
    else
      flash[:error] = t("training_requests.create.failure", product: @product)
    end
    redirect_to facility_path(current_facility)
  end

  # GET /facilities/:facility_id/training_requests
  def index
    @training_requests = current_facility.training_requests
  end

  # DELETE /facilities/:facility_id/training_requests/:id
  def destroy
    if @training_request.destroy
      flash[:notice] = t("training_requests.destroy.success", flash_arguments)
    else
      flash[:error] = t("training_requests.destroy.failure", flash_arguments)
    end
    redirect_to facility_training_requests_path(current_facility)
  end

  private

  def flash_arguments
    @flash_arguments ||= {
      user: @training_request.user.to_s,
      product: @training_request.product.to_s,
    }
  end

  def load_product
    @product =
      Product
      .active
      .where(facility_id: current_facility.id)
      .find_by_url_name!(params[:product_id])
  end
end
