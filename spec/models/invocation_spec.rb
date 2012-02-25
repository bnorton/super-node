require 'spec_helper'

describe SuperNode::Invocation do
  let(:defaults) {{ "class" => "SuperNode::Nom", "args" => [] }}
    let(:super_node) { mock(SuperNode::Invocation) }
    let(:super_node_worker) { mock(SuperNode::Worker) }

  describe "#new" do
    let(:time) { Time.now }

    it "should save the queue_id" do
      inv = SuperNode::Invocation.new(defaults.merge({
        "queue_id" => "abc123"
      }))
      inv.queue_id.should == "abc123"
    end

    it "should save the token" do
      inv = SuperNode::Invocation.new(defaults.merge({
        "metadata" => {
          "queue_id" => 1,
          "created_at" => time
        }
      }))
      inv.metadata.should == {
        "queue_id" => 1,
        "created_at" => time
      }
    end

    it "should error when passed a string" do
      expect {
        SuperNode::Invocation.new("hey")
      }.to raise_error
    end
  end

  describe "#validations" do
    it "should require params" do
      expect {
        SuperNode::Invocation.new()
      }.to raise_error(ArgumentError)
    end

    it "should require a existant class" do
      expect {
        SuperNode::Invocation.new({"class" => "SuperNode::Nom"})
      }.not_to raise_error
    end

    it "should error on a non-existant class" do
      expect {
        SuperNode::Invocation.new({"class" => "RandomClassNameHere"})
      }.to raise_error(ArgumentError)


    end

    it "should respond to perform" do
      # expect {
        SuperNode::Invocation.new({"class" => "SuperNode::Nom"})
      # }.not_to raise_error
    end

    it "should error when it doesn't respond to perform" do
    Class.new.respond_to?(:perform).should be_false
      expect {
        SuperNode::Invocation.new({"class" => "Class"})
      }.to raise_error(Exception)
    end

    it "should respond to the method name" do
      expect {
        SuperNode::Invocation.new({
          "class" => "SuperNode::Nom",
          "method" => "verify"
        })
      }.to raise_error(Exception)
    end
  end

  describe "#save" do
    it "should add itself to a queue upon save" do
      SuperNode::Worker.stub(:new).and_return(super_node_worker)

      inv = SuperNode::Invocation.new({
          "class" => "SuperNode::Nom",
          "method" => "perform"
        })
      inv.save
    end
  end

  describe "#as_json" do
    it "should save the class and args" do
      inv = SuperNode::Invocation.new(defaults.merge({
        "class" => "SuperNode::Nom",
        "args" => ['hey', 'there']
      }).as_json).to_json

      inv = JSON.parse(inv)
      inv['class'].should == "SuperNode::Nom"
      inv['args'].should == ['hey', 'there']
    end

    it "should export and import correctly" do
      invocation_json = SuperNode::Invocation.new({
        'class' => 'SuperNode::Nom',
        'method' => 'perform',
        'queue_id' => '10',
      }).as_json.to_json

      expect {
        SuperNode::Invocation.new(JSON.parse(invocation_json))
      }.not_to raise_error
    end
  end
end
