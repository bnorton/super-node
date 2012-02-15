require 'spec_helper'

describe SuperNode::Worker do
  let(:invocation) { mock(SuperNode::Invocation) }

  describe "#initialize" do
    describe "manually" do
      before do
        invocation.stub(:bucket_id).and_return("10")
        invocation.stub(:to_json).and_return('{"hi": "in there"}')
      end

      it "should push the invocation to Sidekiq" do
        Sidekiq::Client.should_receive(:push).with(invocation.bucket_id, hash_including('args' => ['{"hi": "in there"}']))

        SuperNode::Worker.new(invocation)
      end
    end

    describe "#perform" do
      it "should exist" do
        SuperNode::Worker.new.respond_to?(:perform).should be_true
      end

      it "should be called with a valid invocation object" do
        invocation_json = SuperNode::Invocation.new({
          'class' => 'SuperNode',
          'method' => 'perform',
          'bucket_id' => '10'
        }).to_json

        expect {
          SuperNode::Invocation.new(JSON.parse(invocation_json))
        }.not_to raise_error
      end

      it "should make the invocation" do

      end

      it "should make the callback after an invocation" do

      end
    end
  end


  describe "#enqueue" do
    it "should exist" do
      SuperNode::Worker.new.respond_to?(:enqueue).should be_true
    end
  end
end
