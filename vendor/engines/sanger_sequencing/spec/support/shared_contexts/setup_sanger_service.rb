# frozen_string_literal: true

RSpec.shared_context "Setup Sanger Service" do
  let(:facility) { FactoryBot.create(:setup_facility, sanger_sequencing_enabled: true) }
  let!(:service) { FactoryBot.create(:setup_service, facility:) }
  let(:purchaser) { FactoryBot.create(:user) }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: purchaser) }
  let!(:price_policy) { FactoryBot.create(:service_price_policy, price_group: PriceGroup.base, product: service) }
  let(:facility_staff) { FactoryBot.create(:user, :staff, facility:) }
end
