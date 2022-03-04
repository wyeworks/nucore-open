require "rails_helper"

RSpec.describe User do
	it "does requires unique employee ids" do
		create(:user, umass_emplid: 'id_2')
		should validate_uniqueness_of(:umass_emplid)
	end
end
