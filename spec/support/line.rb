RSpec.configure do |config|
  config.before(:each) do |example|
    if example.metadata[:with_line].present?
      allow(LineClient).to receive(:send).and_return(Net::HTTPResponse.new(1.0, "200", "OK"))
      allow(LineClient).to receive(:send_video).and_return(Net::HTTPResponse.new(1.0, "200", "OK"))
      allow(LineClient).to receive(:send_image).and_return(Net::HTTPResponse.new(1.0, "200", "OK"))
      allow(LineClient).to receive(:flex).and_return(Net::HTTPResponse.new(1.0, "200", "OK"))
    end
  end
end

