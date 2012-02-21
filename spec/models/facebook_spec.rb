require 'spec_helper'

describe SuperNode::Facebook do
  def defaults
    {
      'access_token' => "AAgjk329gsdf3",
      'queue_id' => "10",
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
      }.to raise_error(ArgumentError)
    end
  end

  describe "#fetch" do
    before do
      invocation.stub(:to_json).and_return({
        "class" => "SuperNode::Facebook",
        "method" => "fetch",
        "args" => [{:arg => 'val'}],
        "queue_id" => "siq_10",
      })
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
        red.zadd facebook.queue_id, Time.now.to_i + i, ActiveSupport::JSON.encode(node.to_json)
      end

      now = Time.now.to_i + 100 # make sure we get all 51
      Time.stub(:now).and_return(now)

      red.zcard(facebook.queue_id).should == 51

      batches = facebook.batchify
      batches.length.should == 2
      batches.collect {|b| b.access_token }.uniq.should == [facebook.access_token]

      red.zcard(facebook.queue_id).should == 0
    end
  end

  describe "#to_json" do
    it "should return valid attributes" do
      JSON.parse(ActiveSupport::JSON.encode(facebook.to_json)).should == {
        'queue_id' => facebook.queue_id,
        'access_token' => facebook.access_token,
        'metadata' => nil,
      }
    end

    it "should be reversable" do
      encoded = ActiveSupport::JSON.encode(facebook.to_json)
      JSON.parse(encoded).should == JSON.parse(ActiveSupport::JSON.encode(SuperNode::Facebook.new(JSON.parse(encoded)).to_json))
    end
  end

  describe "#queue_id" do
    it "should have a default" do
      facebook.save
      facebook.queue_id = nil
      facebook.queue_id.should =~ /_default/
    end
  end

  describe "#base_url" do
    it "should be a graph url" do
      SuperNode::Facebook.base_url.should =~ /graph\.facebook/
    end
  end

  describe "#url_from_paging" do
    let(:url) { "https://graph.facebook.com/nike/feed?format=json"}

    it "should parse into the relative url" do
      SuperNode::Facebook.url_from_paging(url).should == "nike/feed?format=json"
    end
  end
end