require 'spec_helper'

describe SuperNode::Invocation do
  let(:defaults) {{ "class" => "SuperNode" }}
    let(:super_node) { mock(SuperNode::Invocation) }
    let(:super_node_queue) { mock(SuperNode::Queue) }

  describe "#new" do
    let(:time) { Time.now }

    it "should save the batch_id" do
      inv = SuperNode::Invocation.new(defaults.merge({
        "batch_id" => "abc123"
      }))
      inv.batch_id.should == "abc123"
    end

    it "should save the token" do
      inv = SuperNode::Invocation.new(defaults.merge({
        "metadata" => {
          "batch_id" => 1,
          "created_at" => time
        }
      }))
      inv.metadata.should == {
        "batch_id" => 1,
        "created_at" => time
      }
    end
  end

  describe "#validations" do
    it "should require params" do
      expect {
        SuperNode::Invocation.new()
      }.to raise_error(SuperNode::ArgumentError)
    end

    it "should require a existant class" do
      expect {
        SuperNode::Invocation.new({"class" => "SuperNode"})
      }.not_to raise_error
    end

    it "should error on a non-existant class" do
      expect {
        SuperNode::Invocation.new({"class" => "RandomClassNameHere"})
      }.to raise_error(SuperNode::ArgumentError)
    end

    it "should respond to perform" do
      expect {
        SuperNode::Invocation.new({"class" => "SuperNode"})
      }.not_to raise_error
    end

    it "should error when it doesn't respond to perform" do
      SuperNode::Queue.respond_to?(:perform).should be_false
      expect {
        SuperNode::Invocation.new({"class" => "SuperNode::Queue"})
      }.to raise_error(SuperNode::ArgumentError)
    end

    it "should respond to the method name" do
      expect {
        SuperNode::Invocation.new({
          "class" => "SuperNode",
          "method" => "verify"
        })
      }.not_to raise_error(SuperNode::MethodNotFound)
    end
  end

  describe "#save" do
    it "should add itself to a queue upon save" do
      SuperNode::Queue.stub(:new).and_return(super_node_queue)
      super_node_queue.should_receive(:enqueue).and_return(true)

      inv = SuperNode::Invocation.new({
          "class" => "SuperNode",
          "method" => "verify!"
        })
      inv.save
    end
  end
end