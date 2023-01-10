# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifier do
  let(:email) { ActionMailer::Base.deliveries.last }
  let(:facility) { create(:setup_facility) }
  let(:order) { create(:purchased_order, product: product) }
  let(:product) { create(:setup_instrument, facility: facility) }
  let(:user) { order.user }

  if EngineManager.engine_loaded?(:c2po)
    describe ".statement" do
      let(:account) { FactoryBot.create(:purchase_order_account, :with_account_owner) }
      let(:statement) { FactoryBot.create(:statement, facility: facility, account: account) }
      let(:email_html) { email.html_part.to_s.gsub(/&nbsp;/, " ") } # Markdown changes some whitespace to &nbsp;
      let(:email_text) { email.text_part.to_s }

      before do
        Notifier.statement(
          user: user,
          facility: facility,
          account: account,
          statement: statement,
        ).deliver_now
      end

      it "generates a statement email", :aggregate_failures do
        expect(email.to).to eq [user.email]
        expect(email.subject).to include(I18n.t(".Statement"))
        expect(email_html).to include(statement.account.to_s)
        expect(email_text).to include(statement.account.to_s)
      end
    end
  end

  describe ".review_orders" do
    let(:accounts) do
      FactoryBot.create_list(:setup_account, 2, owner: user, facility: facility)
    end
    let(:email_html) { email.html_part.to_s.gsub(/&nbsp;/, " ") } # Markdown changes some whitespace to &nbsp;
    let(:email_text) { email.text_part.to_s }

    before(:each) do
      Notifier.review_orders(user: user,
                             facility: facility,
                             accounts: accounts).deliver_now
    end

    it "generates a review_orders notification", :aggregate_failures do
      expect(email.to).to eq [user.email]
      expect(email.subject).to include("Orders For Review: #{facility.abbreviation}")

      [email_html, email_text].each do |email_content|
        expect(email_content)
          .to include("/transactions/in_review")
          .and include(accounts.first.description)
          .and include(accounts.last.description)
      end
    end
  end

  describe ".user_update" do
    let(:account) do
      FactoryBot.create(:setup_account, owner: user, facility: facility)
    end
    let(:email_html) do
      email.html_part.to_s
           .gsub(/&nbsp;/, " ") # Markdown changes some whitespace to &nbsp;
           .gsub(/&ldquo;/, "\"").gsub(/&rdquo;/, "\"") # Translate quotes
    end
    let(:email_text) { email.text_part.to_s }
    let(:admin_user) { FactoryBot.create(:user) }

    before(:each) do
      Notifier.user_update(user: user,
                           created_by: admin_user,
                           role: AccountUser::ACCOUNT_PURCHASER,
                           send_to: "john@example.com",
                           account: account).deliver_now
    end

    it "generates a user_update notification", :aggregate_failures do
      expect(email.to).to eq ["john@example.com"]
      expect(email.subject).to include("#{user} has been added to your #{I18n.t('app_name')} Payment Source")

      [email_html, email_text].each do |email_content|
        expect(email_content)
          .to include(
            "#{user} has been added to the #{I18n.t('app_name')} Payment Source \"#{account}\" as Purchaser by administrator #{admin_user}",
          )
      end
    end
  end
end
