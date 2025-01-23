RSpec.shared_examples "raises specified error" do |request_symbol_or_block, error_class|
  it "raises #{error_class}" do
    if request_symbol_or_block.is_a?(Symbol)
      expect { send(request_symbol_or_block) }.to raise_error(error_class)
    else
      expect { instance_exec(&request_symbol_or_block) }.to raise_error(error_class)
    end
  end
end
