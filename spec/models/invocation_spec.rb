require 'spec_helper'

describe SuperNode::Invocation do
  let(:defaults) {{ "class" => "SuperNode::Nom" }}
    let(:super_node) { mock(SuperNode::Invocation) }
    let(:super_node_worker) { mock(SuperNode::Worker) }

  describe "#new" do
    let(:time) { Time.now }

    it "should save the bucket_id" do
      inv = SuperNode::Invocation.new(defaults.merge({
        "bucket_id" => "abc123"
      }))
      inv.bucket_id.should == "abc123"
    end

    it "should save the token" do
      inv = SuperNode::Invocation.new(defaults.merge({
        "metadata" => {
          "bucket_id" => 1,
          "created_at" => time
        }
      }))
      inv.metadata.should == {
        "bucket_id" => 1,
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
      }.to raise_error(SuperNode::ArgumentError)
    end

    it "should require a existant class" do
      expect {
        SuperNode::Invocation.new({"class" => "SuperNode::Nom"})
      }.not_to raise_error
    end

    it "should error on a non-existant class" do
      expect {
        SuperNode::Invocation.new({"class" => "RandomClassNameHere"})
      }.to raise_error(SuperNode::ArgumentError)


    end

    it "should respond to perform" do
      expect {
        SuperNode::Invocation.new({"class" => "SuperNode::Nom"})
      }.not_to raise_error
    end

    it "should error when it doesn't respond to perform" do
      SuperNode::Worker.respond_to?(:perform).should be_false
      expect {
        SuperNode::Invocation.new({"class" => "SuperNode::Queue"})
      }.to raise_error(SuperNode::ArgumentError)
    end

    it "should respond to the method name" do
      expect {
        SuperNode::Invocation.new({
          "class" => "SuperNode::Nom",
          "method" => "verify"
        })
      }.to raise_error(SuperNode::MethodNotFound)
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

  describe "#to_json" do
    it "should save the class" do
      inv = SuperNode::Invocation.new(defaults.merge({
        "class" => "SuperNode::Nom"
      })).to_json

      JSON.parse(inv)['class'].should == "SuperNode::Nom"
    end

    it "should export and import correctly" do
      invocation_json = SuperNode::Invocation.new({
        'class' => 'SuperNode::Nom',
        'method' => 'perform',
        'bucket_id' => '10'
      }).to_json

      expect {
        SuperNode::Invocation.new(JSON.parse(invocation_json))
      }.not_to raise_error
    end
  end
end
