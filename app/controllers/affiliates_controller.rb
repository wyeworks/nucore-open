# frozen_string_literal: true

class AffiliatesController < GlobalSettingsController

  def index
    @affiliates = Affiliate.alphabetical.destroyable
  end

  def new
    @affiliate = Affiliate.new
  end

  def create
    @affiliate = Affiliate.create(affiliate_params)
    return render action: :new unless @affiliate.errors.empty?

    flash[:notice] = "Affiliate #{@affiliate.name} created"
    redirect_to affiliates_path
  end

  def edit
    id = params[:id]

    begin
      @affiliate = Affiliate.find(id.to_i)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Affiliate with id #{id} not found!"
      return redirect_to affiliates_path
    end
  end

  def update
    id = params[:id]

    begin
      @affiliate = Affiliate.find(id.to_i)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Affiliate with id #{id} not found!"
    else
      return render action: :edit unless @affiliate.update(affiliate_params)

      flash[:notice] = "Affiliate #{@affiliate.name} updated"
    end

    redirect_to affiliates_path
  end

  def destroy
    id = params[:id]

    begin
      affiliate = Affiliate.find(id.to_i)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Affiliate with id #{id} not found!"
    else
      affiliate.destroy

      if affiliate.destroyed?
        flash[:notice] = "Affiliate #{affiliate.name} removed"
      else
        flash[:error] = "Affiliate #{affiliate.name} could not be removed"
      end
    end

    redirect_to affiliates_path
  end

  private

  def affiliate_params
    params.require(:affiliate).permit(:name, :subaffiliates_enabled)
  end

end
