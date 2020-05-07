# frozen_string_literal: true

module SplitAccounts

  # When an order detail is tied to a split account, return a collection of
  # spoofed split order details. The split order details are read-only and
  # should never get persisted.
  class OrderDetailSplitter

    attr_accessor :order_detail, :account, :splits, :split_order_details

    # By default, for performance reasons, we won't also split timedata
    # (reservations/occupancies).
    # We only care about calculated costs for export_raw, so we'll exclude doing
    # that calculation by default as well.
    def initialize(order_detail, split_time_data: false, reporting: false)
      @order_detail = order_detail
      @account = order_detail.account
      @splits = account.splits
      @split_order_details = []
      @split_time_data = split_time_data
      @reporting = reporting
    end

    def split
      @split_order_details = splits.map { |split| build_split_order_detail(split) }

      apply_order_detail_remainders
      apply_time_data_remainders if split_time_data?

      split_order_details
    end

    private

    def order_detail_attribute_splitter
      attributes = [
        :quantity,
        :actual_cost,
        :actual_subsidy,
        :estimated_cost,
        :estimated_subsidy,
      ]
      attributes += [:calculated_cost, :calculated_subsidy] if @reporting
      AttributeSplitter.new(*attributes)
    end

    def time_data_splitter
      AttributeSplitter.new(
        :duration_mins,
        :actual_duration_mins,
        :quantity,
        :billable_minutes,
      )
    end

    def associations_to_copy
      [
        :product,
        :journal,
        :statement,
        :order_status,
        :price_policy,
        :created_by_user,
        :order,
      ]
    end

    def build_split_order_detail(split)
      split_order_detail = SplitOrderDetailDecorator.new(order_detail.dup)
      split_order_detail.split = split
      split_order_detail.account = split.subaccount
      order_detail_attribute_splitter.split(order_detail, split_order_detail, split)

      build_split_time_data(split_order_detail, split) if split_time_data?

      # `dup` does not copy over ID. This assignment needs to happen after the
      # reservation/occupancy is set, otherwise ActiveRecord will delete the
      # original reference.
      split_order_detail.id = order_detail.id

      # `dup` does not copy over actual associations, just IDs. When doing reporting
      # on larger datasets, copying over the actual association can prevent
      # N+1s because the "fake" order detail will not think it needs to hit the DB.
      copy_associations(split_order_detail)

      split_order_detail.readonly! # Don't accidentally try to write something to the database
      split_order_detail
    end

    def split_time_data?
      @split_time_data.present?
    end

    def build_split_time_data(split_order_detail, split)
      return unless order_detail.time_data.present?
      split_time_data = SplitTimeDataDecorator.new(order_detail.time_data.dup)
      time_data_splitter.split(order_detail.time_data, split_time_data, split)
      # Warning: if `id` is set on the order_detail when this assignment happens,
      # ActiveRecord will delete the original reference. This was a change in
      # behavior between Rails 4.1 and 4.2.
      split_order_detail.time_data = split_time_data
    end

    def apply_order_detail_remainders
      applier = RemainderApplier.new(order_detail, split_order_details, splits)
      applier.apply_remainders(order_detail_attribute_splitter)
    end

    def apply_time_data_remainders
      return unless order_detail.time_data.present?
      applier = RemainderApplier.new(order_detail.time_data, split_order_details.map(&:time_data), splits)
      applier.apply_remainders(time_data_splitter)
    end

    def copy_associations(split_order_detail)
      associations_to_copy.each do |association|
        split_order_detail.public_send("#{association}=", order_detail.public_send(association))
      end
    end

  end

end
