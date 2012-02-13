require 'spec_helper'

describe BatchesController do
  describe "enqueue" do
    let(:super_node) { mock(SuperNode::Invocation) }

    def make_request
      post :enqueue, :token => "abc123", :data => { :key => :value }
    end

    before do
      SuperNode::Invocation.stub(:new).and_return(super_node)
      super_node.should_receive(:save)
    end

    it "should be success" do
      make_request
      response.response_code.should == 200
    end

    it "should register the request" do
      make_request
    end
  end
end