class ProductDisplayGroupsController < ApplicationController
  layout "two_column"

  admin_tab :all
  before_action :authenticate_user!
  before_action :init_current_facility
  load_and_authorize_resource through: :current_facility
  before_action :load_ungrouped_products

  def index
    @product_display_groups = @product_display_groups.sorted
  end

  def new
  end

  def create
    if @product_display_group.save
      set_positions
      redirect_to({ action: :index }, notice: text("create.success"))
    else
      # create and update behave differently with the associated product_ids. This
      # should only happen in a multi-tab race condition.
      error = @product_display_group.associated_errors.flat_map(&:full_messages).to_sentence
      flash.now[:alert] = error.presence || text("create.error")
      render :new
    end
  end

  def edit
  end

  def update
    if @product_display_group.update(product_display_group_params)
      set_positions
      redirect_to({ action: :index }, notice: text("update.success"))
    else
      flash[:now] = text("update.error")
      render :edit
    end
  # Adding a product that is in another group raises an error rather than just making
  # it `invalid?`. The error is raised on attribute assignment. This should only
  # be an edge case/race condition with multiple tabs, so rescuing the error seemed
  # to be the simplest solution rather than other convoluted logic to work around the issue.
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = @product_display_group.associated_errors.flat_map(&:full_messages).to_sentence
    render :edit
  end

  def destroy
    @product_display_group.destroy
    redirect_to({ action: :index }, notice: text("destroy.success"))
  end

  private

  def product_display_group_params
    params.require(:product_display_group).permit(:name, product_ids: [])
  end

  def load_ungrouped_products
    @ungrouped_products = current_facility.products.without_display_group.alphabetized
  end

  def set_positions
    @product_display_group.product_display_group_products.each do |join|
      position = params[:product_display_group][:product_ids].index(join.product_id.to_s)
      join.update_column(:position, position)
    end
  end

end
