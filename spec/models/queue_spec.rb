require 'spec_helper'
require 'models/queueable_examples'

describe SuperNode::Queue do
  let!(:invocation) { mock(SuperNode::Invocation) }
  let(:queue) do
    SuperNode::Queue.new({
      :invocation => invocation,
      :queue_id => 'content:all',
      :interval => 41
    })
  end

  describe "a fifo queue" do
    it_behaves_like "a queueable model"
  end

  describe "#initialize" do
    it "should gracefully handle 0 argument init" do
      expect {
        SuperNode::Queue.new
      }.not_to raise_error
    end

    it "should have an invocation" do
      queue.invocation.should == invocation
    end

    it "should have a queue_id" do
      queue.queue_id.should == 'content:all'
    end

    it "should have an interval" do
      queue.interval.should == 41
    end
  end

  describe "#exit?" do
    let(:redis) { Sidekiq::Client.redis }

    it "should be true when a key is set is redis" do
      redis.get("#{queue.queue_id}:exit").should be_nil
      queue.exit?.should be_false

      redis.set("#{queue.queue_id}:exit", 'true')
      queue.exit?.should be_true
    end
  end

  describe "#to_invocation" do
    before do
      invocation.should_receive(:to_json).twice.and_return({'hey' => 'there'})
    end

    it "should have the necessary attributes" do
      queue.to_invocation.to_json.should == {
        'class' => 'SuperNode::Queue',
        'method' => 'perform',
        'args' => [{
          'invocation' => invocation.to_json,
          'interval' => 41,
          'queue_id' => 'content:all',
        }]
      }
    end
  end
end