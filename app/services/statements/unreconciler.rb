# frozen_string_literal: true

module Statements

  class Unreconciler

    attr_reader :count, :errors

    def initialize(statement, user)
      @statement = statement
      @user = user
      @count = 0
      @errors = []
    end

    def unreconcile
      return 0 if reconciled_order_details.empty?

      metadata = build_metadata

      OrderDetail.transaction do
        @count = reconciler.unreconcile_all
        @errors = reconciler.full_errors

        if @errors.any?
          @count = 0
          raise ActiveRecord::Rollback
        end
      end

      LogEvent.log(statement, :unreconciled, user, metadata:) if @count > 0

      @count
    end

    private

    attr_reader :statement, :user

    def reconciled_order_details
      @reconciled_order_details ||= statement.order_details.where(state: "reconciled").to_a
    end

    def reconciler
      @reconciler ||= OrderDetails::Reconciler.new(
        statement.order_details.includes(:journal_rows),
        selected_params,
        nil,
      )
    end

    def selected_params
      ActionController::Parameters.new(
        reconciled_order_details.map { |order_detail| order_detail.id.to_s }
                                .index_with { { selected: "1" } }
      )
    end

    def build_metadata
      metadata = {}

      deposit_numbers = distinct_values(:deposit_number)
      reconciled_notes = distinct_values(:reconciled_note)

      metadata[:deposit_numbers] = deposit_numbers if deposit_numbers.any?
      metadata[:reconciled_notes] = reconciled_notes if reconciled_notes.any?

      metadata
    end

    def distinct_values(field)
      reconciled_order_details.filter_map { |order_detail| order_detail.public_send(field)&.strip.presence }.uniq
    end

  end

end
