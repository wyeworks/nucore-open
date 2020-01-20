# frozen_string_literal: true

class MoveCanPurchaseIntoPricePolicy < ActiveRecord::Migration[4.2]

  def self.up
    add_column :price_policies, :can_purchase, :boolean, after: :price_group_id, default: false, null: false

    PricePolicy.reset_column_information
    InstrumentPricePolicy.reset_column_information
    ServicePricePolicy.reset_column_information
    ItemPricePolicy.reset_column_information

    PriceGroupProduct.all.each do |pgp|
      price_policies = PricePolicy.find_all_by_price_group_id_and_product_id(pgp.price_group_id, pgp.product_id)
      if price_policies.any?
        price_policies.each do |pp|
          Rails.logger.debug "updating can_purchase #{pp.id}"
          # don't do validation
          pp.update_attribute(:can_purchase, 1)
        end
      else
        next if pgp.product.type == "Bundle" # skip bundles since they don't have their own price policies
        next if pgp.product.is_archived? # Ignore inactive products

        puts "Missing policies for | #{pgp.product.facility} | ##{pgp.product.id} | #{pgp.product} | #{pgp.price_group} | #{pgp.product.price_policies.size > 0 ? 'Has policies' : 'No policies'}"

      end
    end
  end

  def self.down
    remove_column :price_policies, :can_purchase
  end

end
