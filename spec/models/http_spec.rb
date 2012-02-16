require 'spec_helper'

describe SuperNode::HTTP do
  let(:http) { mock(Net::HTTP) }
  let!(:uri) { URI.parse("https://callback.endpoint.com/now") }
  
  before do
    URI.stub(:parse).and_return(uri)
  end

  shared_examples_for "a connectable interface" do
    it "should post with the correct uri" do
      Net::HTTP.should_receive(:new).with(uri.host, 443).and_return(http)
      http.should_receive(:use_ssl=).with(true)
      http.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      "Net::HTTP::#{type.to_s.capitalize}".constantize.should_receive(:new).with(uri.request_uri).and_return(conn)
      http.should_receive(:request).with(conn)

      SuperNode::HTTP.new("https://callback.endpoint.com/now").send(type)
    end

    it "should make a network connection" do
      stub_request(type, "https://callback.endpoint.com/now").
         with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

      SuperNode::HTTP.new("https://callback.endpoint.com/now").send(type)
    end
  end

  describe "#post" do
    let!(:conn) { mock(Net::HTTP::Post) }
    def type; :post; end

    it_behaves_like "a connectable interface"    
  end

  describe "#get" do
    let!(:conn) { mock(Net::HTTP::Get) }
    def type; :get; end

    it_behaves_like "a connectable interface"
  end
end
