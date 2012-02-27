require 'spec_helper'

describe SuperNode do
  describe "#perform" do
    it "should exist" do
      SuperNode.respond_to?(:perform).should be_true
    end
  end
  describe "#verfiy!" do
    it "should exist" do
      SuperNode.respond_to?(:verify!).should be_true
    end

    it "should do nothing when given no callback_url" do
      expect {
        SuperNode.verify!
      }.not_to raise_error
    end
    
    it "should POST to the callback_url" do
      stub_request(:post, "https://google.com/").
         with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})      
      SuperNode.verify!("callback_url" => 'http://google.com').should be_true
    end
  end
end