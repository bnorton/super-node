require 'spec_helper'

describe SuperNode::FacebookNode do
  def defaults
    {
      "access_token" => "AABBaskdfl",
      "relative_url" => "me/feed",
      "method" => 'GET'
    }
  end

  before do
    now = Time.now
    Time.stub(:now).and_return(now)
  end

  describe "#initialize" do
    let(:facebook) do
      SuperNode::FacebookNode.new(defaults) 
    end

    describe "#validations" do
      it "should be valid" do
        expect {
          facebook.save
        }.not_to raise_error
      end

      it "should require a relative_url" do
        facebook.relative_url = nil
        expect {
          facebook.save
        }.to raise_error(SuperNode::ArgumentError)
      end
    end

    describe "#next_page" do
      it "should get the next page"
    end
  end

  describe "#to_json" do
    let(:node) { SuperNode::FacebookNode.new(defaults).tap(&:save) }

    it "should include all attributes" do
      node.to_json.should == ActiveSupport::JSON.encode({
        "created_at" => Time.now,
        "node" => node.to_node,
      })
    end
  end

  describe "#to_node" do
    let(:node) { SuperNode::FacebookNode.new(defaults).tap(&:save) }
    it "should leave off the access token" do
      node.access_token = nil
      node.to_node.should == {
        "relative_url" => "me/feed",
        "method" => "GET",
      }
    end

    it "should include the access token" do
      node.relative_url.should_not be_blank
      node.to_node.should == {
        "relative_url" => "me/feed",
        "method" => "GET",
        "access_token" => "AABBaskdfl",
      }
    end
  end
end
