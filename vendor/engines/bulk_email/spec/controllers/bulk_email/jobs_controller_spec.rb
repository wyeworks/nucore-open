# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe BulkEmail::JobsController do
  render_views

  let(:facility) { FactoryBot.create(:facility) }

  before(:all) { create_users }
  before(:each) do
    @authable = facility # controller_spec_helper requires @authable
    @params = { facility_id: facility.url_name }
  end

  describe "GET #index" do
    let!(:bulk_email_jobs) do
      FactoryBot.create_list(:bulk_email_job, 3, facility:)
    end

    before(:each) do
      @action = "index"
      @method = :get

      maybe_grant_always_sign_in :director
      do_request
    end

    it "assigns @bulk_email_jobs, paginated" do
      expect(assigns(:bulk_email_jobs))
        .to match(bulk_email_jobs)
        .and be_respond_to(:per_page)
    end
  end

  describe "GET #show" do
    let(:bulk_email_job) { FactoryBot.create(:bulk_email_job, facility:) }

    before(:each) do
      @action = "show"
      @method = :get
      @params[:id] = bulk_email_job.id

      maybe_grant_always_sign_in :director
      do_request
    end

    it { expect(assigns(:bulk_email_job)).to eq(bulk_email_job) }
  end
end
