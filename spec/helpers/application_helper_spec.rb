require 'spec_helper'
require 'controller_spec_helper'
describe ApplicationHelper do
  describe "#menu_facilities" do
  	before :all do
  	  create_users
  	end
    
    before :each do      
      @facility1 = FactoryGirl.create(:facility)
      @facility2 = FactoryGirl.create(:facility)
      @facility3 = FactoryGirl.create(:facility)
    end
    def session_user
      @user
    end

  	it "should return only facilities with a role" do
      @user = @guest
      UserRole.grant(@user, UserRole::FACILITY_DIRECTOR, @facility1)
      UserRole.grant(@user, UserRole::FACILITY_STAFF, @facility2)

      expect(menu_facilities.size).to eq(2)
      expect(menu_facilities).to contain_all [@facility1, @facility2]
    end

    it "should return only facilities with a role for global admins" do
      @user = @admin
      UserRole.grant(@user, UserRole::FACILITY_DIRECTOR, @facility1)
      UserRole.grant(@user, UserRole::FACILITY_STAFF, @facility2)
      expect(menu_facilities.size).to eq(2)
      expect(menu_facilities).to contain_all [@facility1, @facility2]
    end

    it "should return only facilities with a role for billing admins" do
      @user = @billing_admin
      UserRole.grant(@user, UserRole::FACILITY_DIRECTOR, @facility1)
      UserRole.grant(@user, UserRole::FACILITY_STAFF, @facility2)
      expect(menu_facilities.size).to eq(2)
      expect(menu_facilities).to contain_all [@facility1, @facility2]
    end
  end
end