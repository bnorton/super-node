require 'spec_helper'
require 'models/queueable_examples'

describe SuperNode::Facebook::Queue do
  def defaults
    {
      :access_token => "AAgjk329gsdf3",
      :queue_id => "11",
    }
  end

  let!(:queue) { SuperNode::Facebook::Queue.new(defaults) }
  let(:invocation) { mock(SuperNode::Invocation) }
  let(:batch) { mock(SuperNode::Facebook::Batch) }

  it_behaves_like "a priority queue"

  describe "#initialize" do
    it "should be valid" do
      expect {
        SuperNode::Facebook::Queue.new(defaults)
      }.not_to raise_error
    end

    it "should require a Facebook access_token" do
      args = defaults.slice(:queue_id)
      expect {
        SuperNode::Facebook::Queue.new(args)
      }.to raise_error(ArgumentError)
    end
  end

  describe "#fetch" do
    def json
      {
        :class => "SuperNode::Facebook::Queue",
        :method => "fetch",
        :args => [{:arg => 'val'}],
        :queue_id => "siq_10"
      }
    end

    before do
      invocation.stub(:as_json).and_return(json)
    end

    it "should batchify and save each invocation" do
      queue.should_receive(:batchify).and_return([batch])
      batch.should_receive(:to_invocation).and_return(invocation)
      invocation.should_receive(:save)

      queue.fetch({})
    end

    it "should push invocations to sidekiq" do
      Sidekiq::Client.should_receive(:push).with(nil, {
        'class' => 'SuperNode::Worker',
        'args' => [json]},
      )

      SuperNode::Worker.new(invocation)
    end
  end

  describe "#batchify" do
    let(:redis) { Sidekiq.redis }

    it "should create two batches" do
      51.times do |i|
        node = SuperNode::Facebook::Node.new({
          :relative_url => "#{i*20}/feed"
        })
        redis.zadd(queue.queue_id, Time.now.to_i + i, node.as_json.to_json)
      end

      now = Time.now.to_i + 100 # make sure we get all 51
      Time.stub(:now).and_return(now)

      redis.zcard(queue.queue_id).should == 51

      batches = queue.batchify
      batches.length.should == 2
      batches.collect {|b| b.access_token }.uniq.should == [queue.access_token]

      redis.zcard(queue.queue_id).should == 0
    end
  end

  describe "#as_json" do
    it "should return valid attributes" do
      JSON.parse(queue.as_json.to_json).should == {
        'queue_id' => queue.queue_id,
        'access_token' => queue.access_token,
        'metadata' => nil,
      }
    end

    it "should be reversable" do
      encoded = queue.as_json.to_json
      JSON.parse(encoded).should == JSON.parse(SuperNode::Facebook::Queue.new(JSON.parse(encoded)).as_json.to_json)
    end
  end

  describe "#queue_id" do
    it "should have a default" do
      queue.queue_id = nil
      queue.queue_id.should =~ /_default/
    end
  end

  describe "#base_url" do
    it "should be a graph url" do
      SuperNode::Facebook::Queue.base_url.should =~ /graph\.facebook/
    end
  end

  describe "#url_from_paging" do
    let(:url) { "https://graph.facebook.com/nike/feed?format=json"}

    it "should parse into the relative url" do
      SuperNode::Facebook::Queue.url_from_paging(url).should == "nike/feed?format=json"
    end
  end
end