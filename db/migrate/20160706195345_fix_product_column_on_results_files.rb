# frozen_string_literal: true

class FixProductColumnOnResultsFiles < ActiveRecord::Migration[4.2]

  class StoredFile < ActiveRecord::Base

    belongs_to :order_detail

  end

  def up
    files = StoredFile.where("product_id IS NULL AND order_detail_id IS NOT NULL").includes(:order_detail)
    files.each do |f|
      f.update_column(:product_id, f.order_detail.product_id)
    end
  end

  def down
    # do nothing
  end

end
