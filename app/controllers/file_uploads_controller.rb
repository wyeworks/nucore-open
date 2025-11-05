# frozen_string_literal: true

class FileUploadsController < ApplicationController

  admin_tab           :all
  before_action       :check_acting_as
  before_action       :init_current_facility
  before_action       :init_product
  skip_before_action  :verify_authenticity_token, only: :create

  load_and_authorize_resource class: StoredFile, except: [:download, :upload_sample_results]

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /facilities/1/services/3/files?file_type=info
  # GET /facilities/1/services/3/files?file_type=template
  # GET /facilities/1/services/3/files?file_type=template_result
  def index
    @file = @product.stored_files.new(file_type: params[:file_type])
    @files = @product.stored_files.where(file_type: @file.file_type || params[:file_type])
  end

  # GET /facilities/:facility_id/:product/:product_id/files/:file_type/:id
  def download
    redirect_to(
      @product
        .stored_files
        .where(file_type: params[:file_type])
        .find(params[:id])
        .download_url,
    )
  end

  # POST /facilities/1/services/3/files
  def create
    @file = @product.stored_files.new(create_params.merge(created_by: session_user.id))
    @files = @product.stored_files.where(file_type: @file.file_type || params[:file_type])

    if @file.save
      flash[:notice] = "File uploaded"
      redirect_to [current_facility, @product, :file_uploads, file_type: @file.file_type]
    else
      render :index
    end
  end

  # POST /facilities/:facility_id/:product/:product_id/upload_sample_results
  def upload_sample_results
    options = { file: params[:qqfile],
                name: params[:qqfilename].presence || params[:qqfile].original_filename,
                file_type: params[:file_type],
                order_detail: OrderDetail.find(params[:order_detail_id]),
                product: @product,
                created_by: current_user.id }

    @upload = @product.stored_files.new(options)
    authorize! :upload_sample_results, @upload

    if @upload.save
      ResultsFileNotifier.new(@upload).notify if @upload.sample_result?
      respond_to do |format|
        format.json { render json: { success: true } }
        format.html { head :ok }
      end
    else
      errors = @upload.errors.map(&:message).to_sentence
      respond_to do |format|
        format.json { render json: { error: errors } }
        format.html { render plain: errors, status: 400 }
      end
    end
  end

  # GET /facilities/1/services/3/files/product_survey
  def product_survey
    @file = @product.stored_files.new(file_type: "template")
    @survey = UrlService.new
  end

  def create_product_survey
    @flash_notice = nil
    if params[:stored_file]
      create_product_survey_from_file
    else
      create_product_survey_from_url
    end
    flash[:notice] = @flash_notice if @flash_notice
    if @redirect_to
      redirect_to(@redirect_to)
    else
      render :product_survey
    end
  end

  def destroy
    @file = @product.stored_files.find(params[:id])

    if @product.stored_files.destroy(@file)
      flash[:notice] = "The file was deleted successfully"
    else
      flash[:error] = "An error was encountered while attempting to delete the file"
    end

    # use return_to if it was sent
    @return_to = params[:return_to]

    if request.xhr?
      head :ok
    elsif @file.file_type == "template"
      redirect_to(@return_to || product_survey_path(current_facility, @product.parameterize, @product))
    else
      redirect_to(@return_to || [current_facility, @product, :file_uploads, file_type: @file.file_type])
    end
  end

  private

  def create_params
    params.require(:stored_file).permit(:name, :file_type, :file)
  end

  def init_product
    if params[:product]
      # Use the older route behavior
      # TODO: Remove this once all the necessary routes are removed (see routes.rb:355)
      klass = params[:product]
      @product = current_facility.send(klass).find_by!(url_name: params[:product_id])
    else
      id_param = params.except(:facility_id).keys.detect { |k| k.end_with?("_id") }
      class_name = id_param.sub(/_id\z/, "").camelize
      @product = current_facility
                 .products
                 .of_type(class_name)
                 .find_by!(url_name: params[id_param])
    end
  end

  def create_product_survey_from_file
    @file = @product.stored_files.new(create_params.merge(created_by: session_user.id, name: "Order Form Template"))
    @file.transaction do
      begin
        unless @product.stored_files.template.all?(&:destroy)
          raise ActiveRecord::Rollback
        end
        @file.save!
        @flash_notice = "Order File Template uploaded"
        @redirect_to = product_survey_path(current_facility, @product.parameterize, @product)
      rescue => e
        @file.errors.add(:base, "Order File Template delete error: #{e.message}")
        raise ActiveRecord::Rollback
      end
    end
    @survey = UrlService.new
  end

  def create_product_survey_from_url
    survey_param = UrlService.name.underscore.to_sym

    if params[survey_param].blank? || params[survey_param][:location].blank?
      @survey = UrlService.new
      @survey.errors.add(:base, "No location specified")
    else
      begin
        url = params[survey_param][:location]
        ext = UrlService.find_or_create_by(location: url)
        esp = ExternalServicePasser.where(passer: @product, external_service_id: ext.id).first

        if esp
          @flash_notice = "That Online Order Form already exists"
        else
          @flash_notice = "Online Order Form added"
          ExternalServicePasser.create!(passer: @product, external_service: ext)
        end

        @redirect_to = product_survey_path(current_facility, @product.parameterize, @product)
      rescue => e
        @survey ||= UrlService.new
        @survey.errors.add(:base, "Online Order Form add error: #{e.message}")
      end
    end
    @file = @product.stored_files.new(file_type: "template")
  end

end
