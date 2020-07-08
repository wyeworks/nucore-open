# frozen_string_literal: true

class ProductApprover

  class Stats

    attr_reader :access_groups_changed, :granted_product_users, :revoked_product_users

    def initialize
      @access_groups_changed = 0
      @granted_product_users = []
      @revoked_product_users = []
    end

    def grant(product_user)
      @granted_product_users << product_user
    end

    def granted
      @granted_product_users.count
    end

    def revoke(product_user)
      @revoked_product_users << product_user
    end

    def revoked
      @revoked_product_users.count
    end

    def access_group_change
      @access_groups_changed += 1
    end

    def access_groups_changed?
      @access_groups_changed > 0
    end

    def grants_changed?
      granted + revoked > 0
    end

  end

  def initialize(all_products, user, approver)
    @all_products = all_products
    @user = user
    @approver = approver
  end

  def update_approvals(products_to_approve, access_group_hash = nil)
    access_group_hash ||= {}
    @all_products.each_with_object(Stats.new) do |product, stats|
      if products_to_approve.include?(product)
        product_user = approve_access(product)
        stats.grant(product_user) if product_user
        update_access_group(product, access_group_hash[product.id.to_s]) && stats.access_group_change
      else
        product_user = revoke_access(product)
        stats.revoke(product_user) if product_user
      end
    end
  end

  def approve_access(product)
    create_product_user(product) unless product.can_be_used_by?(@user)
  end

  def revoke_access(product)
    destroy_product_user(product) if product.can_be_used_by?(@user)
  end

  def update_access_group(product, access_group_id)
    product_user = product.find_product_user(@user) || return
    update_product_user_access_group(
      product_user,
      ProductAccessGroup.find_by(id: access_group_id),
    )
  end

  def update_product_user_access_group(product_user, product_access_group)
    return if product_user.product_access_group == product_access_group
    product_user.product_access_group = product_access_group
    product_user.save
  end

  private

  def create_product_user(product)
    ProductUserCreator.create(product: product, user: @user, approver: @approver)
  end

  def destroy_product_user(product)
    product_user = get_product_user(product)
    product_user.try(:destroy)
  end

  def get_product_user(product)
    product.product_users.find_by(user_id: @user.id)
  end

end
