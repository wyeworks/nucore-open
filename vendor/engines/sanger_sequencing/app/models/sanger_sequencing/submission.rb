# frozen_string_literal: true

module SangerSequencing

  class Submission < ApplicationRecord

    self.table_name = "sanger_sequencing_submissions"

    validates :savable_samples, length: { minimum: 1 }, on: :update

    belongs_to :order_detail, class_name: "::OrderDetail"
    belongs_to :batch, class_name: "SangerSequencing::Batch", inverse_of: :submissions
    has_one :order, through: :order_detail
    has_one :user, through: :order
    has_one :facility, through: :order
    has_many :samples, inverse_of: :submission

    accepts_nested_attributes_for :samples, allow_destroy: true

    delegate :order_id, :user, :order_status, :note, :product, :ordered_at, to: :order_detail
    delegate :purchased?, to: :order
    alias purchased_at ordered_at

    scope :purchased, -> { joins(order_detail: :order).merge(Order.purchased).merge(OrderDetail.order(ordered_at: :desc)) }
    scope :for_facility, ->(facility) { where(orders: { facility_id: facility.id }) }

    BATCHABLE_STATES = %w(new inprocess complete).freeze
    scope :ready_for_batch, lambda {
      purchased
        .merge(OrderDetail.where(state: BATCHABLE_STATES))
        .where(batch_id: nil)
    }

    def self.for_product_group(product_group)
      if product_group.present?
        where(order_details: { product_id: ProductGroup.where(group: product_group).pluck(:product_id) })
      else
        where.not(order_details: { product_id: ProductGroup.pluck(:product_id) })
      end
    end

    def has_results_files?
      order_detail.sample_results_files.present?
    end

    # You cannot edit the quantity of a bundled product, so If the order is
    # placed via a bundle, then we should not be able to edit the quantity.
    def quantity_editable?
      order_detail.bundle.blank?
    end

    def create_prefilled_sample
      transaction do
        sample = samples.new
        sample.save(validate: false)
        customer_sample_id = ("%04d" % sample.id).last(4)
        sample.update_column(:customer_sample_id, customer_sample_id)
        sample
      end
    end

    private

    def savable_samples
      samples.reject(&:marked_for_destruction?)
    end

  end

end
