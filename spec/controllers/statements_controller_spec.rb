# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe StatementsController do
  before(:all) do
    create_users
  end

  before(:each) do
    @authable = create_nufs_account_with_owner
  end

  describe "GET show" do
    let(:user) { User.find_by(username: "owner") }
    let(:admin) { User.find_by(username: "admin") }
    let(:statement) { create(:statement, account_id: user.accounts.first.id, created_by: admin.id) }
    let(:order) { create(:order, user:, created_by: user.id, account_id: user.accounts.first.id) }
    let(:product) { create(:setup_item) }
    let(:order_detail) { create(:order_detail, statement:, product:, order:) }

    before do
      sign_in user
      get :show, params: { account_id: user.accounts.first.id, id: statement.id, format: :pdf }
    end

    it "renders a PDF" do
      expect(response.code).to eq("200")
      expect(response.headers["Content-Type"]).to eq("application/pdf; charset=utf-8")
    end
  end
end
