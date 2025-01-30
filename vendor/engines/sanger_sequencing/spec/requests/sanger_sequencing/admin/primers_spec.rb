# frozen_string_literal: true

require "rails_helper"

RSpec.describe "sanger_sequencing/admin/primers", feature_setting: { sanger_enabled_service: true } do
  let(:facility) { create(:setup_facility, sanger_sequencing_enabled: true) }
  let(:admin) { create(:user, :administrator) }

  shared_examples "forbids normal users" do
    describe "as normal user", :disable_requests_local do
      let(:user) { create(:user) }

      before { login_as user }

      it "returns 403" do
        action.call

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "index" do
    let(:action) do
      proc do
        get facility_sanger_sequencing_admin_primers_path(facility)
      end
    end

    include_examples "forbids normal users"

    describe "as admin" do
      before { login_as admin }

      it "returns ok" do
        action.call

        expect(response).to have_http_status(:ok)
      end

      it "includes facility primers" do
        facility.sanger_sequencing_primers.create!(name: "Watermelon")

        action.call

        expect(page).to have_content("Manage Core Primers")
        expect(page).to have_content("Watermelon")
      end

      it(
        "does not render mange primers link if ff is disabeld",
        feature_setting: { sanger_enabled_service: false }
      ) do
        action.call

        expect(page).to_not have_content("Manage Core Primers")
      end
    end
  end

  describe "edit" do
    let(:action) do
      proc do
        get edit_facility_sanger_sequencing_admin_primers_path(facility)
      end
    end

    include_examples "forbids normal users"

    describe "as admin" do
      before { login_as admin }

      it "renders a form" do
        action.call

        expect(page).to have_css("form.edit_facility")
      end
    end
  end

  describe "update" do
    let(:action) do
      proc do |sanger_sequencing_primers_attributes = []|
        put(
          facility_sanger_sequencing_admin_primers_path(facility),
          params: { facility: { sanger_sequencing_primers_attributes: } }
        )
      end
    end

    include_examples "forbids normal users"

    describe "as admin" do
      before { login_as admin }

      it "is successful" do
        action.call

        expect(response).to have_http_status(:found)
        expect(response.location).to eq(
          facility_sanger_sequencing_admin_primers_url(facility)
        )

        get response.location
        expect(page).to have_content("Core Primers updated successfully")
      end

      it "allows to create a primer" do
        expect { action.call([{ name: "Tomato" }]) }.to(
          change do
            facility.sanger_sequencing_primers.where(name: "Tomato").count
          end.from(0).to(1)
        )

        expect(response).to have_http_status(:found)
      end

      it "allows to destroy" do
        primer = facility.sanger_sequencing_primers.create(name: "Banana")

        expect { action.call([{ id: primer.id, _destroy: true }]) }.to(
          change do
            facility.sanger_sequencing_primers.where(name: primer.name).count
          end.from(1).to(0)
        )

        expect(response).to have_http_status(:found)
      end

      it "allows to edit" do
        primer = facility.sanger_sequencing_primers.create(name: "Banana")

        expect { action.call([{ id: primer.id, name: "Cucumber" }]) }.to(
          change do
            primer.reload.name
          end.from("Banana").to("Cucumber")
        )

        expect(response).to have_http_status(:found)
      end

      it "returns validation error" do
        action.call([{ name: "" }])

        expect(response).to have_http_status(:unprocessable_entity)
        expect(page).to have_content("Please fix the errors below")
      end
    end
  end
end
