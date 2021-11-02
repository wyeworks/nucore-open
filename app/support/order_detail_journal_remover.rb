# frozen_string_literal: true

class OrderDetailJournalRemover

  def self.remove_from_journal(order_detail)
    OrderDetail.transaction do
      order_detail.current_journal_rows.each do |journal_row|
        journal_row.try(:destroy)
        order_detail.update!(journal_id: nil)
      end
    end
  end

end
