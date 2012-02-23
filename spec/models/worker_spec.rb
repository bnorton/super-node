require 'spec_helper'

describe SuperNode::Worker do
  let(:invocation) { mock(SuperNode::Invocation) }

  describe "#initialize" do
    describe "manually" do
      before do
        # invocation.stub(:queue_id).and_return("10")
        invocation.stub(:to_json).and_return('{"hi": "in there"}')
      end

      it "should push the invocation to Sidekiq" do
        Sidekiq::Client.should_receive(:push).with(nil, hash_including('args' => ['{"hi": "in there"}']))

        SuperNode::Worker.new(invocation)
      end
    end
  end

  describe "#perform" do
    let(:invocation) do
      SuperNode::Invocation.new({
        'class' => 'SuperNode::Nom',
        'method' => 'perform',
        'queue_id' => '10'
      })
    end

    it "should exist" do
      SuperNode::Worker.new.respond_to?(:perform).should be_true
    end

    it "should be called with a valid invocation object" do
      invocation_json = ActiveSupport::JSON.encode(invocation.to_json)

      expect {
        SuperNode::Invocation.new(JSON.parse(invocation_json))
      }.not_to raise_error
    end

    it "should cache the invocation" do
      worker = SuperNode::Worker.new(invocation)
      worker.invocation.should == invocation
    end

    it "should make the callback after an invocation" do

    end
  end

  describe "#enqueue" do
    it "should exist" do
      SuperNode::Worker.new.respond_to?(:perform).should be_true
    end
  end
end
