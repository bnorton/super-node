require 'spec_helper'

describe SuperNode::HTTP do
  let(:http) { mock(Net::HTTP) }
  let(:post) { mock(Net::HTTP::Post) }
  let!(:uri) { URI.parse("https://callback.endpoint.com/now") }

  describe "#post" do
    before do
      # Net::HTTP.stub(:new).and_return(http)
      # Net::HTTP::Post.stub(:new).and_return(post)
      URI.stub(:parse).and_return(uri)
    end
    it "should post with the correct uri" do
      Net::HTTP.should_receive(:new).with(uri.host, 443).and_return(http)
      http.should_receive(:use_ssl=).with(true)
      http.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      Net::HTTP::Post.should_receive(:new).with(uri.request_uri).and_return(post)
      http.should_receive(:request).with(post)

      SuperNode::HTTP.new("https://callback.endpoint.com/now").post
    end

    it "should make a network connection" do
      stub_request(:post, "https://callback.endpoint.com/now").
         with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

      SuperNode::HTTP.new("https://callback.endpoint.com/now").post
    end
  end
end
