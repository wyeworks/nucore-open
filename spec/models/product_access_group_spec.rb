# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductAccessGroup do
  before :each do
    @facility = FactoryBot.create(:facility)
    @facility_account = FactoryBot.create(:facility_account, facility: @facility)
    @instrument = @product = FactoryBot.create(:instrument,
                                               facility: @facility,
                                               facility_account: @facility_account)
    @restriction_levels = []
    3.times do
      @restriction_levels << FactoryBot.create(:product_access_group, product_id: @product.id)
    end
    @restriction_level = @restriction_levels[0]
  end
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :product }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:product_id).case_insensitive }

  it "removing the level should also remove the join to the scheduling rule" do
    @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
    @rule.product_access_groups << @restriction_level

    expect(@rule.product_access_groups.size).to eq(1)

    @restriction_level.destroy
    @rule.reload
    expect(@rule.product_access_groups).to be_empty
  end

  it "should nullify the product users's instrument restrcition when it's deleted" do
    @user = FactoryBot.create(:user)
    @product_user = ProductUser.create(product: @instrument, user: @user, approved_by: @user.id, product_access_group: @restriction_level)
    expect(@product_user.product_access_group_id).to eq(@restriction_level.id)
    @restriction_level.destroy
    @product_user.reload
    expect(@product_user.product_access_group_id).to be_nil
  end
end
