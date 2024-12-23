# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalCutoffDatesController do
  describe "as a normal user" do
    let(:user) { FactoryBot.create(:user) }
    before { sign_in user }

    context "does not give access to index" do
      it_behaves_like "raises specified error", -> { get :index }, CanCan::AccessDenied
    end

    context "does not give access to create" do
      it_behaves_like "raises specified error", -> { post :create, params: { journal_cutoff_date: { cutoff_date: 1.month.ago } } }, CanCan::AccessDenied
    end

    it "does not give access to update" do
      cutoff = JournalCutoffDate.create(cutoff_date: 1.month.from_now)
      expect { put :update, params: { id: cutoff.id, journal_cutoff_date: {} } }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "as a global admin" do
    let(:user) { FactoryBot.create(:user, :administrator) }
    before { sign_in user }

    describe "#new" do
      describe "default dates", :time_travel do
        let(:now) { Time.zone.parse("2016-02-02") }
        let(:time_setting) { "14:30" }
        before { allow(Settings).to receive_message_chain(:financial, :default_journal_cutoff_time).and_return(time_setting) }

        context "with no existing cutoffs" do
          it "defaults to the beginning of next month" do
            get :new
            expect(assigns(:journal_cutoff_date).cutoff_date).to eq(Time.zone.parse("2016-03-01 14:30"))
          end
        end

        context "with an existing cutoff in the past" do
          let!(:existing) { JournalCutoffDate.create(cutoff_date: Time.zone.parse("2015-06-04 14:30")) }

          it "defaults to the beginning of next month" do
            get :new
            expect(assigns(:journal_cutoff_date).cutoff_date).to eq(Time.zone.parse("2016-03-01 14:30"))
          end
        end

        context "with an existing cutoffs in the future" do
          let!(:existing) { JournalCutoffDate.create(cutoff_date: Time.zone.parse("2016-06-04")) }
          let!(:existing2) { JournalCutoffDate.create(cutoff_date: Time.zone.parse("2016-05-04")) }

          it "defaults to the beginning of month following the existing cutoff" do
            get :new
            expect(assigns(:journal_cutoff_date).cutoff_date).to eq(Time.zone.parse("2016-07-01 14:30"))
          end
        end
      end
    end

    describe "#create" do
      def do_request
        post :create, params: { journal_cutoff_date: { cutoff_date: { date: cutoff_date, hour: "3", minute: "15", ampm: "PM" } } }
      end

      describe "success" do
        describe "with a string param" do
          let(:cutoff_date) { "06/10/2016" }

          it "interprets month/day correctly" do
            do_request
            expect(JournalCutoffDate.last.cutoff_date).to eq(Time.zone.parse("2016-06-10 15:15"))
          end
        end
      end

      describe "with an empty cutoff date" do
        let(:cutoff_date) { "" }

        it "does not create a new cutoff date" do
          expect { do_request }.not_to change(JournalCutoffDate, :count)
        end

        it "renders the form again" do
          do_request
          expect(response).to render_template :new
        end
      end
    end

    describe "#update" do
      let!(:journal_cutoff_date) { JournalCutoffDate.create(cutoff_date: Time.zone.parse("2016-06-10 15:15")) }

      def do_request
        put :update, params: { id: journal_cutoff_date.id, journal_cutoff_date: { cutoff_date: { date: new_cutoff_date } } }
      end

      describe "success" do
        let(:new_cutoff_date) { "07/10/2016" }

        it "updates the model" do
          expect { do_request }.to change { journal_cutoff_date.reload.cutoff_date }.to(Time.zone.parse("2016-07-10"))
        end
      end

      describe "failure" do
        let(:new_cutoff_date) { "" }

        it "does not update the model" do
          expect { do_request }.not_to change { journal_cutoff_date.reload.cutoff_date }
        end

        it "renders the edit view again" do
          do_request
          expect(response).to render_template :edit
          expect(assigns(:journal_cutoff_date)).to eq(journal_cutoff_date)
        end
      end
    end

    describe "#destroy" do
      let!(:journal_cutoff_date) { JournalCutoffDate.create(cutoff_date: 1.month.from_now) }

      it "destroys the cutoff date" do
        expect { delete :destroy, params: { id: journal_cutoff_date.id } }.to change(JournalCutoffDate, :count).by(-1)
      end
    end
  end
end
