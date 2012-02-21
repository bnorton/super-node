require 'spec_helper'

describe SuperNode::Queue do
  let!(:invocation) { mock(SuperNode::Invocation) }
  let(:queue) do
    SuperNode::Queue.new({
      'invocation' => invocation,
      'queue_id' => 'content:all',
      'interval' => 41
    })
  end

  describe "#initialize" do
    it "should gracefully handle 0 argument init" do
      expect {
        SuperNode::Queue.new
      }.not_to raise_error
    end

    it "should have an invocation" do
      queue.invocation.should == invocation
    end

    it "should have a queue_id" do
      queue.queue_id.should == 'content:all'
    end

    it "should have an interval" do
      queue.interval.should == 41
    end
  end

  shared_examples_for "a priority queue" do
    let(:items) { [{:v => 2}, {:v => 1}, {:v => -5}] }
    before do
      @now = Time.now
      Time.stub(:now).and_return(@now)
    end

    describe "#push" do
      it "should take a string" do
        queue.push('{"hey": 10}', Time.now-5.minutes)
        queue.pop.should == [{ 'hey' => 10 }]
      end

      it "should take a hash" do
        queue.push({:hey => 10}, Time.now-5.minutes)
        queue.pop.should == [{ 'hey' => 10 }]
      end

      it "should take an array" do
        queue.length.should == 0
        queue.push(5.times.map {|i| {i.to_s => i } }, (Time.now - 3.minutes))
        queue.length.should == 5

        items = []
        queue.pop.each_with_index { |i, j| items << i[j.to_s] }
        items.should == [0, 1, 2, 3, 4]
        queue.length.should == 0
      end
    end

    describe "#length" do
      it "should be accurate" do
        queue.length.should == 0
        queue.push(['1', '3', '4'])
        queue.length.should == 3
      end
    end

    describe "#size" do
      it "should be accurate" do
        queue.size.should == 0
        queue.push(['1', '3', '4'])
        queue.size.should == 3
      end
    end

    describe "#zcard" do
      it "should be accurate" do
        queue.zcard.should == 0
        queue.push(['1', '3', '4'])
        queue.zcard.should == 3
      end
    end

    describe "#pop" do
      before do
        [2, 1, -5].each_with_index do |ago, i|
          queue.push(items[i], Time.now + ago.minutes)
        end
      end

      it "should pop things from the past" do
        queue.pop.should == [items.last.stringify_keys]
        queue.pop.should == []
      end

      it "should return items in order" do
        queue.pop

        @now += 3.minutes
        Time.stub(:now).and_return(@now)
        queue.pop.should == items[0..1].map{ |i| i.stringify_keys }.sort{|x,y| x['v'] <=> y['v']}
        queue.pop.should == []
      end

      it "should return a hash" do
        queue.pop.first.class.should == Hash
      end
    end
  end

  it_behaves_like "a priority queue"

end