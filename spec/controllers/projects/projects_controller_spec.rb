# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper" # for the #facility_operators helper method

def facility_operator_roles
  # Translates helper roles to User factory traits
  facility_operators.map do |role|
    case role
    when :admin
      :facility_administrator
    when :senior_staff, :staff
      role
    else
      :"facility_#{role}"
    end
  end
end

RSpec.describe ProjectsController, type: :controller do
  let(:facility) { FactoryBot.create(:facility) }

  describe "GET #edit" do
    let(:project) { FactoryBot.create(:project, facility: facility) }

    def do_request
      get :edit, params: { facility_id: facility.url_name, id: project.id }
    end

    describe "when not logged in" do
      it { expect { do_request }.to raise_error(CanCan::AccessDenied) }
    end

    describe "when logged in" do
      shared_examples_for "it allows edit views" do |role|
        let(:user) { FactoryBot.create(:user, role, facility: facility) }

        before(:each) do
          sign_in user
          do_request
        end

        it "shows the edit view" do
          expect(response.code).to eq("200")
          expect(assigns(:project)).to eq(project)
        end
      end

      facility_operator_roles.each do |role|
        context "as #{role}" do
          it_behaves_like "it allows edit views", role
        end
      end
    end
  end

  describe "GET #new" do
    def do_request
      get :new, params: { facility_id: facility.url_name }
    end

    describe "when not logged in" do
      it { expect { do_request }.to raise_error(CanCan::AccessDenied) }
    end

    describe "when logged in" do
      shared_examples_for "it allows new views" do |role|
        let(:user) { FactoryBot.create(:user, role, facility: facility) }

        before(:each) do
          sign_in user
          do_request
        end

        it "shows the new view" do
          expect(response.code).to eq("200")
          expect(assigns(:project)).to be_kind_of(Project).and be_new_record
        end
      end

      facility_operator_roles.each do |role|
        context "as #{role}" do
          it_behaves_like "it allows new views", role
        end
      end
    end
  end

  describe "GET #show" do
    let(:project) { FactoryBot.create(:project, facility: facility) }

    def do_request
      get :show, params: { facility_id: facility.url_name, id: project.id }
    end

    describe "when not logged in" do
      it { expect { do_request }.to raise_error(CanCan::AccessDenied) }
    end

    describe "when logged in" do
      shared_examples_for "it allows show views" do |role|
        let(:user) { FactoryBot.create(:user, role, facility: facility) }

        before(:each) do
          sign_in user
          do_request
        end

        it "shows the show view" do
          expect(response.code).to eq("200")
          expect(assigns(:project)).to be_kind_of(Project).and be_persisted
        end
      end

      facility_operator_roles.each do |role|
        context "as #{role}" do
          it_behaves_like "it allows show views", role
        end
      end
    end
  end

  describe "POST #create" do
    def do_request
      post :create, params: {
        facility_id: facility.url_name,
        project: { name: name, description: description },
      }
    end

    let(:name) { "Project Name" }
    let(:description) { "A project description" }

    describe "when not logged in" do
      it { expect { do_request }.to raise_error(CanCan::AccessDenied) }
    end

    describe "when logged in" do
      shared_examples_for "it allows project creation" do |role|
        let(:created_project) { Project.last }
        let(:user) { FactoryBot.create(:user, role, facility: facility) }

        before(:each) do
          sign_in user
          do_request
        end

        it "creates a new project" do
          is_expected.to redirect_to facility_project_path(facility, created_project)
          expect(created_project.name).to eq(name)
          expect(created_project.description).to eq(description)
          expect(created_project).to be_active
        end
      end

      facility_operator_roles.each do |role|
        context "as #{role}" do
          it_behaves_like "it allows project creation", role
        end
      end
    end
  end

  describe "PUT #update" do
    let(:active?) { true }
    let(:project) { FactoryBot.create(:project, name: "Old name", facility: facility) }
    let(:new_description) { "New project description" }
    let(:new_name) { "New project name" }

    def do_request
      put :update, params: {
        facility_id: facility.url_name,
        id: project.id,
        project: {
          active: active?,
          description: new_description,
          name: new_name,
        },
      }
    end

    describe "when not logged in" do
      it { expect { do_request }.to raise_error(CanCan::AccessDenied) }
    end

    describe "when logged in" do
      shared_examples_for "it allows update" do |role|
        let(:user) { FactoryBot.create(:user, role, facility: facility) }

        before(:each) do
          sign_in user
          do_request
          project.reload
        end

        context "when providing a project name" do
          it "updates the project" do
            expect(project.name).to eq(new_name)
            expect(project.description).to eq(new_description)
            expect(project).to be_active
            is_expected.to redirect_to facility_project_path(facility, project)
            expect(flash[:notice]).to include("was updated")
          end
        end

        context "when unsetting the active flag" do
          let(:active?) { false }

          it "sets the project inactive then redirects to its 'show' view" do
            expect(project).not_to be_active
            is_expected.to redirect_to facility_project_path(facility, project)
          end
        end

        context "when the project name is blank" do
          let(:new_name) { "" }

          it "does not update the project" do
            expect(project.reload.name).to eq("Old name")
            expect(assigns[:project].errors[:name]).to include("may not be blank")
            is_expected.to render_template(:edit)
          end
        end
      end

      facility_operator_roles.each do |role|
        context "as #{role}" do
          it_behaves_like "it allows update", role
        end
      end
    end
  end
end
