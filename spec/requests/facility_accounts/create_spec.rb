# frozen_string_literal: true

require "rails_helper"

RSpec.describe "creating accounts", :use_test_account do
  let(:admin) { create(:user, :administrator) }
  let(:user) { create(:user) }

  before do
    login_as admin
  end

  describe "facility accounts" do
    let(:facility_account_type) do
      facility_account_class.to_s
    end
    let(:facility_account_class) { TestAccount }
    let(:account_number) { build(:test_account).account_number }

    before do
      creation_disabled_types = Account.config.creation_disabled_types

      allow(Account.config).to receive(:creation_disabled_types) do
        creation_disabled_types - [facility_account_type]
      end
    end

    before do
      allow(Account.config).to receive(:creation_enabled_types) do
        [facility_account_type]
      end
      allow(Account.config).to receive(:facility_account_types) do
        [facility_account_type]
      end
      allow(Account.config).to receive(:account_types) do
        [facility_account_type]
      end
    end

    context "when facility is cross facility" do
      let(:facility) { Facility.cross_facility }

      describe "per facility account" do
        context "when it's globally managed" do
          before do
            allow(Account.config)
              .to(receive(:facility_account_globally_managed_types)) do
                [facility_account_type]
              end
          end

          it "can create the account type" do
            get new_facility_account_path(facility, owner_user_id: user.id)

            expect(page).to(
              have_content(facility_account_class.model_name.human)
            )
          end

          it "includes a facility select field" do
            get(
              new_facility_account_path(
                facility,
                owner_user_id: user.id,
                account_type: facility_account_type,
              )
            )

            expect(page).to have_field(
              "#{facility_account_type.underscore}[facility_ids][]",
            )
          end

          describe "account creation" do
            let(:some_facility) { create(:facility) }

            it "can create the account assigning a facility" do
              params = {
                facility_account_type.underscore => {
                  account_number:,
                  description: "Some description",
                  facility_ids: [some_facility.id],
                }
              }

              expect do
                post(
                  facility_accounts_path(
                    facility,
                    owner_user_id: user.id,
                    account_type: facility_account_type,
                  ),
                  params:,
                )
              end.to(
                change(Account, :count).by(1)
              )

              expect(Account.last.facilities).to match([some_facility])
            end
          end
        end

        context "when it's not globally managed" do
          before do
            allow(Account.config)
              .to(receive(:facility_account_globally_managed_types)) do
                []
              end
          end

          it "does not show the account type on creation" do
            skip if Account.config.global_account_types.empty?

            get new_facility_account_path(facility, owner_user_id: user.id)

            File.write("account_new.html", response.body)
            expect(page).to have_content("Add Payment Source")
            expect(page).not_to(
              have_content(facility_account_class.model_name.human)
            )
          end
        end
      end
    end

    context "when facility is not cross facility" do
      let(:facility) { create(:setup_facility) }

      describe "per facility account" do
        context "when the account is globally managed" do
          before do
            allow(Account.config)
              .to(receive(:facility_account_globally_managed_types)) do
                [facility_account_type]
              end
          end

          it "shows the account type on creation" do
            get new_facility_account_path(facility, owner_user_id: user.id)

            expect(page).to(
              have_content(facility_account_class.model_name.human)
            )
          end

          it "does not show the facilities select field" do
            get new_facility_account_path(
              facility,
              owner_user_id: user.id,
              account_type: facility_account_type,
            )

            expect(page).to have_content("Add Payment Source")
            expect(page).not_to have_field(
              "#{facility_account_type.underscore}[facility_ids][]",
            )
          end

          it "assigns current facility on creation" do
            params = {
              facility_account_type.underscore => {
                account_number:,
                description: "Some description",
              }
            }

            expect do
              post(
                facility_accounts_path(
                  facility,
                  owner_user_id: user.id,
                  account_type: facility_account_type,
                ),
                params:
              )
            end.to change(Account, :count).by(1)

            expect(Account.last.facilities).to match([facility])
          end
        end
      end
    end
  end

  describe(
    "price groups selection",
    feature_setting: { show_account_price_groups_tab: true },
  ) do
    let(:facility) { create(:setup_facility) }
    let(:account_class) { TestAccount }
    let(:account_type) { account_class.to_s }
    let(:account_number) { build(:test_account).account_number }
    let(:price_group) { PriceGroup.last }

    before do
      creation_disabled_types = Account.config.creation_disabled_types
      allow(Account.config).to receive(:creation_disabled_types) do
        creation_disabled_types - [account_type]
      end
      allow(Account.config).to receive(:creation_enabled_types) do
        [account_type]
      end
      allow(Account.config).to receive(:account_types) do
        [account_type]
      end
    end

    it "shows price groups select checkbox" do
      get new_facility_account_path(facility, owner_user_id: user.id)

      expect(page).to have_field("#{account_type.underscore}[price_groups_relation_ids][]")
    end

    it "can submit price groups" do
      params = {
        account_type.underscore => {
          account_number:,
          description: "Some description",
          price_groups_relation_ids: [price_group.id],
        }
      }

      expect do
        post(
          facility_accounts_path(facility, owner_user_id: user.id, account_type:),
          params:
        )
      end.to change(Account, :count).by(1)

      expect(Account.last.price_groups_relation).to match([price_group])
    end

    describe "price groups options" do
      let(:facility) { create(:facility) }
      let(:other_facility) { create(:facility) }
      let!(:facility_price_group) do
        create(:price_group, facility:)
      end
      let!(:other_facility_price_group) do
        create(:price_group, facility: other_facility)
      end
      let(:account_class) { TestAccount }
      let(:account_type) { account_class.to_s }
      let(:account_type_key) { account_type.underscore }
      let(:price_groups_key) do
        "#{account_type_key}[price_groups_relation_ids][]"
      end

      context "when current facility is not cross facility" do
        let(:current_facility) { facility }

        it "does not show local price group's facility name" do
          get new_facility_account_path(current_facility, owner_user_id: user.id)

          expect(page).to have_select(
            price_groups_key, with_options: [facility_price_group.name],
          )
        end

        it "includes global and facility price groups but not other facilities'" do
          get new_facility_account_path(current_facility, owner_user_id: user.id)

          select_field = page.find_field(price_groups_key)

          options_text = select_field.all("option").map(&:text)

          expect(options_text).to include(PriceGroup.base.name)
          expect(options_text).to include(a_string_matching(facility_price_group.name))
          expect(options_text).not_to include(a_string_matching(other_facility_price_group.name))
        end
      end

      context "when facility is cross facility" do
        let(:current_facility) { Facility.cross_facility }

        it "shows facility price group's with facility name" do
          facility_price_group = create(:price_group, facility: create(:facility))

          get new_facility_account_path(current_facility, owner_user_id: user.id)

          expect(page).to have_select(
            price_groups_key, with_options: [facility_price_group.presenter.long_name],
          )
        end
      end
    end
  end
end
