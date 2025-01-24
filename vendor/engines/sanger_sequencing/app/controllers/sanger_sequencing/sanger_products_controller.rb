# frozen_string_literal: true

module SangerSequencing

  class SangerProductsController < BaseController
    before_action :set_resources
    before_action { @active_tab = "admin_products" }
    before_action { authorize! :manage, current_facility }

    layout "two_column"
    admin_tab :all

    def show
    end

    def edit
    end

    def update
      if @sanger_product.update(sanger_product_params)
        redirect_to [current_facility, @product, :sanger_sequencing, :sanger_product], notice: text(".update.success")
      else
        render :edit
      end
    end

    private

    def sanger_product_groups
      SangerProduct::GROUPS.map do |group|
        [SangerProduct.human_attribute_name("group.#{group}"), group]
      end
    end

    helper_method :sanger_product_groups

    def sanger_product_params
      params.require(:sanger_sequencing_sanger_product).permit(
        :needs_primer,
        :group,
        primers_attributes: [:id, :name, :_destroy]
      )
    end

    def set_resources
      @product = current_facility.products.find_by!(
        url_name: params[:service_id]
      )
      @sanger_product = @product.sanger_product || @product.create_sanger_product_with_default_primers
    end
  end

end
