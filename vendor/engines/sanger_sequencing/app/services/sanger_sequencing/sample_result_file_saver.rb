# frozen_string_literal: true

module SangerSequencing

  class SampleResultFileSaver

    include ActiveModel::Validations

    FILENAME_FORMAT = /\A(\d+)_.+/

    attr_reader :params, :current_user, :stored_file

    validate :filename_has_sample_id
    validate :has_valid_sample

    delegate :name, to: :stored_file

    def initialize(batch, current_user, params)
      @batch = batch
      @params = params
      @current_user = current_user
    end

    def save
      return false unless valid?

      @stored_file = StoredFile.new(name: filename,
                                    file: file,
                                    file_type: "sample_result",
                                    created_by: current_user.id,
                                    order_detail: sample.submission.order_detail,
                                    product_id: sample.submission.order_detail.product_id)
      if stored_file.save
        trigger_notification(stored_file)
        true
      else
        copy_errors_from_file
        false
      end
    end

    def filename
      params[:qqfilename].presence || file.original_filename
    end

    def sample
      return @sample if defined?(@sample)
      @sample = @batch.samples.find_by(id: sample_id)
    end

    private

    def trigger_notification(stored_file)
      ResultsFileNotifier.new(stored_file).notify
    end

    def has_valid_sample
      return unless filename_has_sample_id?
      errors.add(:sample, :blank, id: sample_id) unless sample
    end

    def filename_has_sample_id
      errors.add(:filename, :invalid) unless filename_has_sample_id?
    end

    def filename_has_sample_id?
      sample_id.present?
    end

    def sample_id
      filename.match(FILENAME_FORMAT).try(:[], 1)
    end

    def file
      params[:qqfile]
    end

    def copy_errors_from_file
      stored_file.errors.each do |k, v|
        errors.add(k, v)
      end
    end

  end

end
