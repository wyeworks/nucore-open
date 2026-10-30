# frozen_string_literal: true

class NotePresenceValidator
  def initialize(order_detail)
    @order_detail = order_detail
  end

  def valid?
    if @order_detail.product.user_notes_field_mode.required? && @order_detail.note.blank?
      @order_detail.errors.add(:note, :blank)
      false
    else
      true
    end
  end
end
