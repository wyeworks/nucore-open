class ProductDisplayGroupPositionsController < ApplicationController

  layout "two_column"

  admin_tab :all
  before_action :authenticate_user!
  before_action :init_current_facility
  before_action { authorize! :edit, ProductDisplayGroup }
  before_action :load_product_display_groups

  def edit
  end

  def update
    @product_display_groups.each do |group|
      position = update_params[:product_display_group_ids].index(group.id.to_s)
      group.update!(position: position)
    end
    redirect_to facility_product_display_groups_path, notice: text("success")
  end

  private

  def load_product_display_groups
    @product_display_groups = current_facility.product_display_groups.sorted
  end

  def update_params
    params.require(:product_display_group_positions).permit(product_display_group_ids: [])
  end

end
