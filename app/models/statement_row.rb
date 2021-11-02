# frozen_string_literal: true

class StatementRow < ApplicationRecord

  belongs_to :statement
  belongs_to :order_detail

  validates_presence_of :order_detail_id, :statement_id

  before_destroy { @parent_statement = statement }

  after_destroy do
    if @parent_statement.statement_rows.reload.empty?
      @parent_statement.order_details.each do |order_detail|
        order_detail.update(statement: nil)
      end
      @parent_statement.destroy
    end
  end

  def amount
    order_detail.total
  end

end
