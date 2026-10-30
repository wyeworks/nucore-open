# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessHandlers::OccupancyHandler, type: :service do
  shared_examples_for "a new occupancy" do
    it "creates a new Occupancy" do
      expect { described_class.process(event) }
        .to change(SecureRooms::Occupancy, :count).by(1)
    end
  end

  shared_examples_for "the exit occupancy" do
    it "sets the exit_event and timestamp" do
      expect(occupancy.exit_event).to eq event
      expect(occupancy.exit_at).to be_present
    end
  end

  shared_examples_for "the entry occupancy" do
    it "sets the entry_event and timestamp" do
      expect(occupancy.entry_event).to eq event
      expect(occupancy.entry_at).to be_present
    end
  end

  shared_examples_for "an orphaned occupancy" do
    it "sets orphan status" do
      expect(occupancy).to be_orphan
    end
  end

  shared_examples_for "a problem order" do
    it "results in a problem order" do
      expect(occupancy.order_detail).to be_complete
      expect(occupancy.order_detail).to be_problem
    end
  end

  describe "#process" do
    context "event was not successful" do
      let(:event) { create :event, card_reader: }
      let(:card_reader) { create :card_reader }

      describe "the new occupancy" do
        subject(:occupancy) { described_class.process(event) }

        it { should be_blank }
        it "does not create an occupancy" do
          expect { described_class.process(event) }
            .not_to change(SecureRooms::Occupancy, :count)
        end
      end
    end

    context "event was successful" do
      let(:event) { create :event, :successful, card_reader: }

      context "when there is current_occupant" do
        let(:account) { create :account, :with_account_owner, owner: event.user }
        let!(:existing_occupancy) do
          create(
            :occupancy,
            :active,
            entry_event: event,
            secure_room: card_reader.secure_room,
            user: event.user,
            account:,
          )
        end

        context "exiting" do
          let(:card_reader) { create :card_reader, ingress: false }

          it "updates existing Occupancy" do
            expect { described_class.process(event) }
              .not_to change(SecureRooms::Occupancy, :count)
          end

          it_should_behave_like "the exit occupancy" do
            subject(:occupancy) { described_class.process(event) }
          end
        end

        context "entering" do
          let(:card_reader) { create :card_reader, ingress: true }

          # orders need to be "purchased" but we don't care about the details
          before do
            allow_any_instance_of(OrderDetail).to receive(:valid_for_purchase?).and_return(true)
            allow_any_instance_of(SecureRooms::AccessHandlers::OrderHandler).to receive(:user_exempt_from_purchase?).and_return(false)
          end

          describe "the new occupancy" do
            subject(:occupancy) { described_class.process(event) }

            it_should_behave_like "a new occupancy"
            it_should_behave_like "the entry occupancy"
          end

          describe "the existing occupancy" do
            subject(:occupancy) { existing_occupancy.reload }
            before { described_class.process(event) }

            it_should_behave_like "an orphaned occupancy"
            it_should_behave_like "a problem order"
          end
        end
      end

      context "new_occupant" do
        context "entering" do
          describe "an entry only room" do
            let(:card_reader) { create :card_reader, ingress: true }
            subject(:occupancy) { described_class.process(event) }

            describe "the new occupancy" do
              it_should_behave_like "a new occupancy"
              it_should_behave_like "the entry occupancy"

              it "associates the event to both entry and exit" do
                expect(occupancy.exit_at).to eq(occupancy.entry_at)
                expect(occupancy.exit_event).to eq(event)
              end
            end

            describe "a room with both entry and exit" do
              let!(:card_reader) { create :card_reader, ingress: true }
              let!(:exit_card_reader) { create :card_reader, ingress: false, secure_room: card_reader.secure_room }

              it_should_behave_like "a new occupancy"
              it_should_behave_like "the entry occupancy"

              it "does not have an exit associated with it" do
                expect(occupancy.exit_at).to be_blank
                expect(occupancy.exit_event).to be_blank
              end
            end
          end
        end

        context "exiting" do
          # orders need to be "purchased" but we don't care about the details
          before do
            allow_any_instance_of(OrderDetail).to receive(:valid_for_purchase?).and_return(true)
            allow_any_instance_of(SecureRooms::AccessHandlers::OrderHandler).to receive(:user_exempt_from_purchase?).and_return(false)
          end

          let(:card_reader) { create :card_reader, ingress: false }

          describe "the new occupancy" do
            subject(:occupancy) { described_class.process(event) }

            it_should_behave_like "a new occupancy"
            it_should_behave_like "the exit occupancy"
            it_should_behave_like "an orphaned occupancy"
          end
        end
      end
    end
  end
end
