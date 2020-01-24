# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityFacilityAccountsController do
  render_views

  around(:each) do |example|
    old_form = described_class.form_class
    described_class.form_class = ::FacilityAccountForm
    example.call
    described_class.form_class = old_form
  end

  let(:facility) { create(:facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:senior_staff) { create(:user, :senior_staff, facility: facility) }

  let(:params) { { facility_id: facility.url_name } }

  describe "GET #index" do
    let!(:facility_account) { create(:facility_account, facility: facility) }

    it "allows a director" do
      sign_in director
      get :index, params: params

      is_expected.to render_template "index"
      expect(assigns(:accounts)).to eq([facility_account])
    end

    it "denies senior staff" do
      sign_in senior_staff
      get :index, params: params

      expect(response).to be_forbidden
    end
  end

  describe "GET #new" do
    it "allows a director" do
      sign_in director
      get :new, params: params

      is_expected.to render_template "new"
      expect(assigns(:facility_account)).to be_new_record
    end

    it "denies senior staff" do
      sign_in senior_staff
      get :new, params: params

      expect(response).to be_forbidden
    end
  end

  describe "POST #create" do
    let(:params) { super().merge(facility_account: attributes_for(:facility_account).except(:created_by)) }

    describe "as a director" do
      before { sign_in director }

      it "allows a director to create an account if it is open" do
        expect_any_instance_of(ValidatorFactory.validator_class).to receive(:account_is_open!).and_return(true)

        expect { put :create, params: params }.to change(FacilityAccount, :count).by(1)
        expect(response).to redirect_to(facility_facility_accounts_path)
      end

      it "renders errors if the account is not open" do
        expect_any_instance_of(ValidatorFactory.validator_class).to receive(:account_is_open!).and_raise(ValidatorError, "not open")

        expect { post :create, params: params }.not_to change(FacilityAccount, :count)
        expect(assigns(:facility_account)).to be_new_record
        expect(assigns(:facility_account).errors[:base]).to include("not open")
      end
    end

    it "denies senior staff" do
      sign_in senior_staff
      post :create, params: params

      expect(response).to be_forbidden
    end
  end

  describe "GET #edit" do
    let!(:facility_account) { create(:facility_account, facility: facility) }
    let(:params) { super().merge(id: facility_account.id) }

    it "allows a director to edit" do
      sign_in director
      get :edit, params: params

      is_expected.to render_template "edit"
      expect(assigns(:facility_account)).to eq(facility_account)
    end

    it "denies senior staff" do
      sign_in senior_staff
      get :edit, params: params

      expect(response).to be_forbidden
    end
  end

  describe "PUT #update" do
    let!(:facility_account) { create(:facility_account, facility: facility, is_active: false) }
    let(:params) do
      super().merge(id: facility_account.id, facility_account: { is_active: true })
    end

    it "allows a director to update the account if it is valid" do
      allow_any_instance_of(ValidatorFactory.validator_class).to receive(:account_is_open!).and_return(true)

      sign_in director
      expect { put :update, params: params }.to change { facility_account.reload.active? }.to be(true)
    end

    it "prevents the director from updating it even if it is invalid" do
      allow_any_instance_of(ValidatorFactory.validator_class).to receive(:account_is_open!).and_raise(ValidatorError, "not open")

      sign_in director
      expect { put :update, params: params }.to change { facility_account.reload.active? }.to be(true)
    end

    it "denies senior staff" do
      sign_in senior_staff

      put :update, params: params
      expect(response).to be_forbidden
    end
  end
end
