class AddProductGroupPrimer < ActiveRecord::Migration[4.2]
  def change
    add_column(
      :sanger_seq_product_groups,
      :needs_primer,
      :boolean,
      default: false,
      null: false
    )
  end
end
