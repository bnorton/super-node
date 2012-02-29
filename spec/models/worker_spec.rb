require 'spec_helper'

describe SuperNode::Worker do
  let(:invocation) { mock(SuperNode::Invocation) }

  describe "#initialize" do
    describe "manually" do
      before do
        invocation.stub(:as_json).and_return({'hi' => 'in there'})
      end

      it "should push the invocation to Sidekiq" do
        Sidekiq::Client.should_receive(:push).with(nil, hash_including('args' => [{'hi' => 'in there'}]))

        SuperNode::Worker.new(invocation)
      end
    end
  end

  describe "#perform" do
    let!(:nom) { mock("SuperNode::Nom") }
    let!(:invocation) do
      SuperNode::Invocation.new({
        :class => 'SuperNode::Nom',
        :method => 'locations',
        :queue_id => '10'
      })
    end

    it "should exist" do
      SuperNode::Worker.new.respond_to?(:perform).should be_true
    end

    it "should be called with a valid invocation object" do
      invocation_json = JSON.parse(invocation.as_json.to_json)

      expect {
        SuperNode::Invocation.new(invocation_json)
      }.not_to raise_error
    end

    it "should cache the invocation" do
      worker = SuperNode::Worker.new(invocation)
      worker.invocation.should == invocation
    end

    it "should make the invocation" do
      SuperNode::Nom.should_receive(:new).twice.and_return(nom)
      nom.should_receive(:locations)

      stub_request(:get, "https://justnom.it/locations/here.json?lat=37.7969398498535&lng=-122.399559020996").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

      SuperNode::Worker.new.perform(invocation.as_json)
    end
  end

  describe "#enqueue" do
    it "should exist" do
      SuperNode::Worker.new.respond_to?(:perform).should be_true
    end
  end
end
