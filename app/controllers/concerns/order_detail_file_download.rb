# frozen_string_literal: true

module OrderDetailFileDownload

  extend ActiveSupport::Concern

  def sample_results
    authorize! :sample_results, @order_detail
    redirect_to @order_detail.stored_files.sample_result.find(params[:stored_file_id]).download_url, allow_other_host: true
  end

  def template_results
    authorize! :template_results, @order_detail
    redirect_to @order_detail.stored_files.template_result.find(params[:stored_file_id]).download_url, allow_other_host: true
  end

end
