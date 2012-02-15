require 'spec_helper'

describe SuperNode::Facebook do
  describe "#initialize" do
    let(:facebook) do
      SuperNode::Facebook.new({
        "graph_id" => "12421123",
        "access_token" => "AABBaskdfl",
        "connection_type" => "feed"
      }) 
    end

    describe "#validations" do
      it "should be valid" do
        expect {
          facebook.save
        }.not_to raise_error
      end

      it "should require a graph_id" do
        facebook.graph_id = nil
        expect {
          facebook.save
        }.to raise_error(SuperNode::ArgumentError)
      end

      it "should require an access_token" do
        facebook.access_token = nil
        expect {
          facebook.save
        }.to raise_error(SuperNode::ArgumentError)
      end

      it "should require a connection_type" do
        facebook.connection_type = nil
        expect {
          facebook.save
        }.to raise_error(SuperNode::ArgumentError)
      end
    end

    describe "#next_page" do
      it "should get the next page"
    end
  end
end
