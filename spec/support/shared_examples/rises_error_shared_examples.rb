RSpec.shared_examples "raises specified error" do |request_symbol_or_block, error_class|
  it "raises #{error_class}" do
    if defined?(page) && respond_to?(:visit)
      # This is a system/feature spec using Capybara
      if request_symbol_or_block.is_a?(Symbol)
        send(request_symbol_or_block)
      else
        instance_exec(&request_symbol_or_block)
      end

      case error_class.name
      when "CanCan::AccessDenied"
        expect(page).to have_http_status(:forbidden)
      when "ActiveRecord::RecordNotFound"
        expect(page).to have_http_status(:not_found)
      else
        expect(page.status_code).to be >= 400
      end
    elsif request_symbol_or_block.is_a?(Symbol)
      # This is a controller/request spec
      expect { send(request_symbol_or_block) }.to raise_error(error_class)
    else
      expect { instance_exec(&request_symbol_or_block) }.to raise_error(error_class)
    end
  end
end
