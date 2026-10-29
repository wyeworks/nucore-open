# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailEvent do
  describe ".notify" do
    let(:user) { FactoryBot.create(:user) }

    it "yields on the first invocation" do
      expect { |b| described_class.notify(user, "key", &b) }.to yield_control
    end

    describe "on second invocation" do
      before do
        described_class.notify(user, "key") {}
      end

      it "does not yield on second quick invocation" do
        expect { |b| described_class.notify(user, "key", &b) }.not_to yield_control
      end

      it "does not yield on second invocation if before the wait time" do
        travel_and_return(1.hour) do
          expect { |b| described_class.notify(user, "key", wait: 2.hours, &b) }
            .not_to yield_control
        end
      end

      it "yields on second invocation after the wait time" do
        travel_and_return(3.hours) do
          expect { |b| described_class.notify(user, "key", wait: 2.hours, &b) }
            .to yield_control
        end
      end

      it "yields on an invocation for a different key" do
        expect { |b| described_class.notify(user, "anotherkey", &b) }.to yield_control
      end

      it "yields on an invocation for a different user with the same key" do
        user2 = FactoryBot.create(:user)
        expect { |b| described_class.notify(user2, "key", &b) }.to yield_control
      end
    end
  end

  describe ".key_for" do
    it "renders a plain string" do
      expect(described_class.key_for("testing")).to eq("testing")
    end

    it "accepts an array of strings" do
      expect(described_class.key_for(%w[test abc])).to eq("test/abc")
    end

    it "accepts strings and symbols" do
      expect(described_class.key_for([:test_sym, "test_string"])).to eq("test_sym/test_string")
    end

    it "takes an arbitrary object with a to_s method" do
      class TestingClass
        def to_s
          "test_me"
        end
      end

      expect(described_class.key_for([:test, TestingClass.new])).to eq("test/test_me")
    end
  end
end
