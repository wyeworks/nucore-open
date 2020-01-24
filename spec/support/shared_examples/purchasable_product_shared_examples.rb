# frozen_string_literal: true

RSpec.shared_examples_for "a purchasable product" do
  context "when the product is purchasable" do
    before(:each) do
      allow_any_instance_of(ProductForCart).to receive(:purchasable_by?).and_return(true)
      do_request
    end

    it "sets @add_to_cart to true" do
      expect(assigns[:add_to_cart]).to be true
    end

    it "responds with a success" do
      expect(response).to be_successful
    end

    it "renders the show page" do
      expect(response).to render_template("show")
    end
  end

  context "when the product is not purchasable" do
    before(:each) do
      allow_any_instance_of(ProductForCart).to receive(:purchasable_by?).and_return(false)
    end

    it "sets @add_to_cart to false" do
      do_request
      expect(assigns[:add_to_cart]).to be false
    end

    context "and an error_path is set" do
      let(:error_path) { facility_path(facility) }
      let(:error_message) { "We’re sorry, this product is not available for purchase." }

      before(:each) do
        allow_any_instance_of(ProductForCart).to receive(:error_path).and_return(error_path)
        allow_any_instance_of(ProductForCart).to receive(:error_message).and_return(error_message)
        do_request
      end

      it "redirects to the specified path" do
        expect(response).to redirect_to error_path
      end

      it "sets a notice in the flash to the specified error message" do
        expect(flash[:notice]).to eq error_message
      end
    end

    context "and an error_path is not set" do
      before(:each) do
        allow_any_instance_of(ProductForCart).to receive(:error_path).and_return(nil)
      end

      context "and an error message is set" do
        let(:error_message) { "We’re sorry, this product is not available for purchase." }

        before(:each) do
          allow_any_instance_of(ProductForCart).to receive(:error_message).and_return(error_message)
          do_request
        end

        it "sets a notice in flash.now to the specified error message" do
          expect(flash[:notice]).to eq error_message
        end
      end

      it "renders the show page" do
        do_request
        expect(response).to render_template("show")
      end
    end
  end
end
