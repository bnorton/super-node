require 'spec_helper'

describe SuperNode::Facebook do
  def defaults
    {
      'access_token' => "AAgjk329gsdf3",
      'bucket_id' => "10",
    }
  end

  let!(:facebook) { SuperNode::Facebook.new(defaults) }
  let(:invocation) { mock(SuperNode::Invocation) }
  let(:batch) { mock(SuperNode::FacebookBatch) }

  describe "#initialize" do
    it "should be valid" do
      expect {
        facebook.save
      }.not_to raise_error
    end

    it "should require a Facebook access_token" do
      facebook.access_token = nil
      expect {
        facebook.save
      }.to raise_error(SuperNode::ArgumentError)
    end
  end

  describe "#enqueue" do
    before do
      invocation.stub(:to_json).and_return(ActiveSupport::JSON.encode({
        "class" => "SuperNode::Facebook",
        "method" => "enqueue",
        "args" => [ActiveSupport::JSON.encode({:arg => 'val'})],
        "queue_id" => "siq_10",
      }))
    end

    it "should batchify" do
      SuperNode::Facebook.should_receive(:new).twice.and_return(facebook)

      facebook.should_receive(:batchify).and_return([batch])
      invocation.should_receive(:save)
      batch.should_receive(:to_invocation).and_return(invocation)

      SuperNode::Worker.new.perform(invocation.to_json)
    end

  it "should enqueue as many workers as batches"
  end

  describe "#batchify" do
    let(:red) { SuperNode::Facebook.redis }

    it "should create two batches" do
      51.times do |i|
        node = SuperNode::FacebookNode.new({
          'relative_url' => "#{i*20}/feed"
        })
        red.zadd facebook.queue_id, Time.now.to_i + i, node.to_json
      end

      now = Time.now.to_i + 100
      Time.stub(:now).and_return(now) # make sure we get all 51

      red.zcard(facebook.queue_id).should == 51

      batches = facebook.batchify
      batches.length.should == 2
      batches.collect {|b| b.access_token }.uniq.should == [facebook.access_token]
    end
  end

  describe "#to_json" do
    it "should return valid attributes" do
      JSON.parse(facebook.to_json).should == {
        'bucket_id' => facebook.bucket_id,
        'access_token' => facebook.access_token,
        'metadata' => nil,
        'interval' => facebook.interval,
      }
    end

    it "should be reversable" do
      JSON.parse(facebook.to_json).should == JSON.parse(SuperNode::Facebook.new(JSON.parse(facebook.to_json)).to_json)
    end
  end

  describe "#queue_id" do
    it "should have a default" do
      facebook.save
      facebook.bucket_id = nil
      facebook.queue_id.should =~ /_default/
    end
  end

  describe "#base_url" do
    it "should be a graph url" do
      facebook.base_url.should =~ /graph\.facebook/
    end
  end
end