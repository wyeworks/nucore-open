# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetails::ParamUpdater do
  describe ".permitted_attributes" do
    it "injects the :project_id attribute when the engine is active" do
      expect(OrderDetailBatchUpdater.permitted_attributes)
        .to include(:project_id)
    end
  end
end
