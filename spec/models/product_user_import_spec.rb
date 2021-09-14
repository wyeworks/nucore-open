# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductUserImport do

  let!(:admin) { create(:user, :administrator) }
  let!(:user_1) { create(:user) }
  let!(:user_2) { create(:user) }
  let!(:product_user) { create(:product_user, product: product, user: admin) }
  let(:product) { create(:setup_item) }
  let(:file) { StringIO.new(body) }
  let(:body) { "c,s,v" }

  subject(:import) do
    ProductUserImport.new(
      creator: admin,
      file: file,
      product: product
    )
  end

  context "validations" do
    it { is_expected.to belong_to :product }
    it { is_expected.to belong_to :creator }
    it { is_expected.to validate_presence_of :file }
    it { is_expected.to validate_presence_of :creator }
  end

  describe "#process_upload!" do
    before(:each) { import.process_upload! }

    context "when no Username column exists" do
      let(:body) do
        <<~CSV
          Wrong Column Name
          admin
          director
          user123
        CSV
      end

      it { is_expected.to be_failed }
      it { is_expected.not_to be_persisted }

      it "includes a failure message" do
        expect(import.failures).to include("Uploaded CSV file must include a 'Username' column.  Please try again.")
      end
    end

    context "when all usernames are found (some are skipped)" do
      let(:body) do
        <<~CSV
          Username
          #{admin.username}
          #{user_1.username}
          #{user_2.username}
        CSV
      end

      it { is_expected.to be_new_product_users_added }
      it { is_expected.to be_persisted }

      it "includes a list of added users" do
        expect(import.skipped).to include("* #{admin.username}\n")
        expect(import.successes).to include("* #{user_1.username}\n", "* #{user_2.username}\n")
      end
    end

    context "when some usernames are found and some are not" do
      let(:body) do
        <<~CSV
          Username
          #{admin.username}
          #{user_1.username}
          admin
        CSV
      end

      it { is_expected.to be_failed }
      it { is_expected.not_to be_persisted }

      it "includes a failure message" do
        expect(import.failures).to include("* admin: User not found\n")
      end
    end
  end
end
