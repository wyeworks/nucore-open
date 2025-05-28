# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResultsFileNotifier do
  let(:service) { FactoryBot.create(:setup_service) }
  let(:order) { create(:purchased_order, product: service) }
  let(:stored_file) { FactoryBot.create(:stored_file, :results, order_detail: order.order_details.first) }
  let(:notifier) { described_class.new(stored_file) }

  describe "with notifications enabled", feature_setting: { results_file_notifications: true, my_files: true, reload_routes: true } do
    it "sends a notification" do
      expect { notifier.notify }.to(
        enqueue_mail(ResultsFileNotifierMailer, :file_uploaded)
      )
    end

    describe "notifying a second time" do
      before { notifier.notify }

      describe "shortly after the first one" do
        it "does not send" do
          expect { notifier.notify }.not_to enqueue_mail
        end
      end

      describe "a day later" do
        it "does send" do
          travel_and_return(25.hours) do
            expect { notifier.notify }.to(
              enqueue_mail(ResultsFileNotifierMailer, :file_uploaded)
            )
          end
        end
      end
    end
  end

  describe "with notifications disabled", feature_setting: { results_file_notifications: false } do
    it "does not send a notification" do
      expect { notifier.notify }.not_to enqueue_mail
    end
  end

end
