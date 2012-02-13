require 'spec_helper'

describe SuperNode::Queue do
  describe "#enqueue" do
    it "should exist" do
      SuperNode::Queue.new.respond_to?(:enqueue).should be_true
    end
  end
end
