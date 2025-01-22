# frozen_string_literal: true

module SangerSequencing

  class BatchForm

    extend ActiveModel::Translation

    include ActiveModel::Attributes
    include ActiveModel::Validations

    ORDER_OPTIONS = %w[
      sequential
      odd_first
    ].freeze

    attribute :batch
    attribute :column_order, default: "odd_first"

    delegate :submission_ids, :group, to: :batch

    validates :submission_ids, presence: true
    validate :samples_must_match_submissions
    validate :submission_part_of_other_batch
    validate :submissions_in_correct_facility
    validates :column_order, inclusion: { in: ORDER_OPTIONS }

    def initialize(batch = SangerSequencing::Batch.new)
      super()
      self.batch = batch
    end

    def assign_attributes(params = {})
      batch.assign_attributes(
        submission_ids: params[:submission_ids].to_s.split(","),
        well_plates_raw: (params[:well_plate_data] || {}).values,
        created_by: params[:created_by],
        facility: params[:facility],
        group: params[:group],
      )
    end

    def update_form_attributes(params = {})
      assign_attributes(params)
      save
    end

    def save
      batch.save if valid?
    end

    private

    def submissions_in_correct_facility
      incorrect_facilities = batch.submissions.reject { |s| s.facility == batch.facility }
      if incorrect_facilities.any?
        errors.add(:submission_ids, :invalid_facility, id: incorrect_facilities.map(&:id).join(", "))
      end
    end

    def submission_part_of_other_batch
      changed = Submission.where(id: batch.submission_ids).where.not(batch: nil).pluck(:id)
      if changed.any?
        errors.add(:submission_ids, :submission_part_of_other_batch, id: changed.join(", "))
      end
    end

    def samples_must_match_submissions
      unless submitted_sample_ids.to_set == sample_ids_from_submissions.to_set
        errors.add(:submitted_sample_ids, :must_match_submissions)
      end
    end

    def sample_ids_from_submissions
      batch.submissions.flat_map(&:samples).map { |s| s.id.to_s }
    end

    # The list of all the samples submitted into the form
    def submitted_sample_ids
      batch.well_plates_raw.flat_map(&:values).map(&:to_s).select { |id| id =~ /\A\d+\z/ }
    end

  end

end
