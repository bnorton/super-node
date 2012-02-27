require 'spec_helper'

describe SuperNode::Facebook::Node do
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
    let(:facebook) { SuperNode::Facebook::Node.new(defaults) }

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
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#as_json" do
    let(:node) { SuperNode::Facebook::Node.new(defaults).tap(&:save) }

    it "should include all attributes" do
      node.as_json.should == node.to_node
    end
  end

  describe "when the Node has been fetched" do
    let!(:before_node) { SuperNode::Facebook::Node.new(defaults.merge(:body => "hi")).tap(&:save) }
    let!(:response) do
      {
        "code"=>200,
        "headers"=> [
          {"name"=>"Cache-Control", "value"=>"private, no-cache, no-store, must-revalidate"},
          {"name"=>"ETag", "value"=>"\"1050253aec7b29caff644806927dabfa81406eee\""}, 
          {"name"=>"Expires", "value"=>"Sat, 01 Jan 2000 00:00:00 GMT"}, 
        ],
        "body"=>"{
          \"data\": [
            {\"id\":\"100002518620011_206472486113371\",\"from\":{\"name\":\"Shannon Forbes\",\"id\":\"100002518620011\"},\"story\":\"Shannon Forbes and Kristyn Brigance are now friends.\",\"story_tags\":{\"19\":[{\"id\":9621125,\"name\":\"Kristyn Brigance\",\"offset\":19,\"length\":16}],\"0\":[{\"id\":100002518620011,\"name\":\"Shannon Forbes\",\"offset\":0,\"length\":14}]},\"type\":\"status\",\"created_time\":\"2012-01-10T17:21:59+0000\",\"updated_time\":\"2012-01-10T17:21:59+0000\",\"comments\":{\"count\":0}}
          ],
          \"paging\": {
            \"previous\": \"https://graph.facebook.com/nike/feed?format=json&limit=25&since=1329839041&__previous=1\", 
            \"next\": \"https://graph.facebook.com/nike/feed?format=json&limit=25&until=1327531370\"
          }
        }"
      }
    end
    let!(:after_node) { SuperNode::Facebook::Node.new(before_node.as_json, response) }

    describe "#method" do
      it "should stay the same" do
        before_node.method.should == after_node.method
      end
    end

    describe "#relative_url" do
      it "should stay the same" do
        before_node.relative_url.should == after_node.relative_url
      end
    end

    describe "#body" do
      it "should stay the same" do
        before_node.body.should == after_node.body
      end
    end

    describe "#metadata" do
    end

    describe "#code" do
      it "should reflect the response code" do
        before_node.code.should be_blank
        after_node.code.should == 200
      end
    end

    describe "#data" do
      it "should be decoded" do
        before_node.data.should be_blank
        after_node.data.class.should == Array
        after_node.data.first["id"].should == "100002518620011_206472486113371"
      end
      it "should be the data of the body of the request for that node" do
      end      
    end

    describe "#parse!" do      
      it "should parse the fb response" do
        before_node.parse!(response)
        before_node.code.should == 200
        before_node.data.class.should == Array
      end
    end

    describe "pagination" do
      describe "paginate!" do
        it "should setup the parameters during parse" do
          before_node.should_receive(:paginate!)

          before_node.parse!(response)
        end
      end
      describe "#pagination" do
        it "should return the pagination block" do
          before_node.parse!(response)

          before_node.pagination.should == {
            'next_page' => {
              'access_token' => before_node.access_token,
              'relative_url' => 'nike/feed?format=json&limit=25&until=1327531370',
              'method' => 'GET',
            },
            'previous_page' => {
              'access_token' => before_node.access_token,
              'relative_url' => 'nike/feed?format=json&limit=25&since=1329839041&__previous=1',
              'method' => 'GET',
            }
          }
        end
      end

      describe "#next_page" do
        it "should create a SuperNode::Facebook::Node for the next page" do
          after_node.next_page.class.should == SuperNode::Facebook::Node
        end
      end

      describe "#previous_page" do
        it "should create a SuperNode::Facebook::Node for the previous page" do
          after_node.previous_page.class.should == SuperNode::Facebook::Node
        end
      end
    end
  end

  describe "#to_node" do
    let(:node) { SuperNode::Facebook::Node.new(defaults).tap(&:save) }
    it "should leave off the access token" do
      node.access_token = nil
      node.to_node.should == {
        "relative_url" => "me/feed",
        "method" => "GET"
      }
    end

    it "should include the access token" do
      node.relative_url.should_not be_blank
      node.to_node.should == {
        "relative_url" => "me/feed",
        "method" => "GET",
        "access_token" => "AABBaskdfl"
      }
    end

    it "should include the body" do
      node.body = 'hey'

      node.to_node.should == {
        "relative_url" => "me/feed",
        "method" => "GET",
        'body' => 'hey',
        "access_token" => "AABBaskdfl",
      }
    end
  end
end
