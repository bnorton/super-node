require 'spec_helper'

describe SuperNode::Facebook::Batch do
  def defaults
    {
      :access_token => 'abc123',
      :batch => ['item'],
      :queue_id => 'queue_1'
    }
  end

  let!(:batch) { SuperNode::Facebook::Batch.new(defaults) }

  describe "#initialize" do
    it "should store the access token" do
      batch.access_token.should == defaults[:access_token]
    end

    it "should store the batch itself" do
      batch.batch.should == defaults[:batch]
    end

    it "should store the queue id" do
      batch.queue_id.should == defaults[:queue_id]
    end

    describe "callback" do
      let!(:callback) do
        SuperNode::Invocation.new({
          :class => 'SuperNode::Nom',
          :method => 'locations'
        })
      end

      let!(:batch) do
        SuperNode::Facebook::Batch.new(defaults.merge({
          :callback => callback.as_json
        }))
      end

      it "should store it" do
        batch.callback.as_json.should == callback.as_json
      end

      it "should be a SuperNode::Invocation" do
        batch.callback.class.should == SuperNode::Invocation
      end
    end
  end

  describe "#validations" do
    it "should error when no access token is present" do
      expect {
        SuperNode::Facebook::Batch.new({ :batch => ['item'], :queue_id => 'queue_1' })
      }.to raise_error(ArgumentError)
    end

    it "should error when the batch is empty" do
      expect {
        SuperNode::Facebook::Batch.new({ :access_token => 'abc123', :batch => [], :queue_id => 'queue_1' })
      }.to raise_error(ArgumentError)
    end
  end

  describe "#as_json" do
    it "should return queue id, access token and batch" do
      batch.as_json.should == {
        'queue_id' => 'queue_1',
        'access_token' => 'abc123',
        'batch' => ['item']
      }
    end
  end

  describe "#to_invocation" do
    it "should make a new invocation" do
      batch.to_invocation.as_json.should == SuperNode::Invocation.new({
        'class' => 'SuperNode::Facebook::Batch',
        'method' => 'fetch',
        'queue_id' => 'queue_1',
        'args' => [batch.as_json],
      }).as_json
    end
  end

  describe "#to_batch" do
    it "should represent the batch as facebook expects" do
      batch.to_batch.should == {
        'access_token' => 'abc123',
        'batch' => "[\"item\"]"
      }
    end
  end
end