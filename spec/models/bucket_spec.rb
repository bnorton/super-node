require 'spec_helper'

describe SuperNode::Bucket do
  let(:bucket) do
    SuperNode::Bucket.find_or_create_by_bucket_id({
      'bucket_id' => @next_id,
      'callback_url' => 'anything'
    })
  end
  let(:invocation1) { SuperNode::Invocation.new({"class" => "SuperNode::Worker"}) }
  let(:invocation2) { SuperNode::Invocation.new({"class" => "SuperNode::Nom"}) }

  before do
    @next_id = rand(1<<31).to_s
  end

  describe "#initialize" do
    it "should require an id" do
      expect {
        SuperNode::Bucket.new({
          'callback_url' => "localhost:3000/callback"
        })      
      }.to raise_error(SuperNode::ArgumentError)
    end

    it "should require a callback_url" do
      expect {
        SuperNode::Bucket.new({
          'bucket_id' => @next_id
        })
      }.to raise_error(SuperNode::ArgumentError)
    end

    it "should save the valid attributes" do
      expect {
        bucket
      }.not_to raise_error
    end
  end

  describe "#exists?" do
    it "should return the existence of a bucket" do
      id = "10"
      SuperNode::Bucket.exists?(id).should be_false

      SuperNode::Bucket.find_or_create_by_bucket_id({
        'bucket_id' => id,
        'callback_url' => "localhost:3000/callback"
      })
      SuperNode::Bucket.exists?(id).should be_true
    end
  end

  describe "#find_or_create_by_bucket_id" do
    let(:bucket) do 
      SuperNode::Bucket.find_or_create_by_bucket_id({
        'bucket_id' => @next_id,
        'callback_url' => "localhost:3000/callback"
      })
    end
    it "should return a SuperNode::Bucket" do
      bucket.class.should == SuperNode::Bucket
      bucket.bucket_id = @next_id
    end

    it "should create a new bucket when none exist with that name" do
      SuperNode::Bucket.exists?(@next_id).should be_false
      bucket
      SuperNode::Bucket.exists?(@next_id).should be_true
    end

    it "should return a pre-existing bucket" do
      bucket

      SuperNode::Bucket.exists?(@next_id).should be_true
      SuperNode::Bucket.find_or_create_by_bucket_id({
        'bucket_id' => @next_id,
        'callback_url' => 'anything'
      })
      SuperNode::Bucket.exists?(@next_id).should be_true
    end

    it "should not change the callback_url for a pre-existing bucket" do
      url = bucket.callback_url

      SuperNode::Bucket.find_or_create_by_bucket_id({
        'bucket_id' => @next_id,
        'callback_url' => 'anything'
      }).to_json.should == bucket.to_json

      bucket.callback_url.should == url
    end
  end

  describe "#queue_id" do
    it "should be SuperNode Invocation Queue aka. siq_:bucket_id" do
      bucket.queue_id.should == "siq_#{bucket.bucket_id}"
    end
  end

  describe "#length" do
    it "should return the length of the bucket's queue" do
      before = bucket.length
      bucket.push invocation1
      bucket.length.should == before + 1
    end
  end

  describe "#push" do
    it "should add an item to the bucket's queue" do
      before = bucket.length
      bucket.push invocation1
      bucket.length.should == before + 1
    end
  end

  describe "#pop" do
    it "should get the least recently pushed item" do
      bucket.pop.should be_nil

      bucket.push invocation1
      bucket.push invocation2

      bucket.pop.should == invocation1.to_json
      bucket.pop.should == invocation2.to_json
      bucket.pop.should be_nil
    end
  end

  describe "#to_json" do
    it "should encode the bucket as json" do
      bucket_json = JSON.parse(SuperNode::Bucket.new({
        'bucket_id' => @next_id,
        'callback_url' => 'anything'
      }).to_json)

      bucket_json.should == {
        "bucket_id" => @next_id,
        "callback_url" => "anything"
      }
    end

    it "should parse the bucket from json" do
      bucket_json = SuperNode::Bucket.new({
        'bucket_id' => @next_id,
        'callback_url' => 'anything'
      }).to_json

      bucket = SuperNode::Bucket.new(JSON.parse(bucket_json))
      bucket.callback_url.should == "anything"
      bucket.bucket_id.should == @next_id
    end
  end
end