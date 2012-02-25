shared_examples "a queueable model" do
  let(:items) { [{:v => 2}, {:v => 1}, {:v => -5}] }

  before do
    @now = Time.now
    Time.stub(:now).and_return(@now)
  end

  describe "#push" do
    it "should push a string" do
      queue.push('{"hey": 10}')
      queue.pop.should == [{ 'hey' => 10 }]
    end

    it "should push a hash" do
      queue.push({:hey => 10})
      queue.pop.should == [{ 'hey' => 10 }]
    end

    it "should push an array" do
      queue.length.should == 0
      queue.push(5.times.map {|i| {i.to_s => i } }, (Time.now - 3.minutes))
      queue.length.should == 5

      list = []
      queue.pop.each_with_index { |i, j| list << i[j.to_s] }
      list.should == [0, 1, 2, 3, 4]
      queue.length.should == 0
    end
  end

  describe "#pop" do
    before do
      [2, 1, -5].each_with_index do |ago, i|
        queue.push(items[i])
      end
    end

    it "should pop all items" do
      items.each {|i| i.stringify_keys! }
      queue.pop.should == items.reverse
      queue.pop.should == []
    end
  end

  describe "#length" do
    it "should be accurate" do
      queue.length.should == 0
      queue.push(%w(1 3 4))
      queue.length.should == 3
    end
  end

  describe "#size" do
    it "should be accurate" do
      queue.size.should == 0
      queue.push(%w(1 3 4))
      queue.size.should == 3
    end
  end
end

shared_examples "a priority queue" do
  it_behaves_like "a queue"

  describe "#zcard" do
    it "should be accurate" do
      queue.zcard.should == 0
      queue.push(%w(1 10 3 4 3 10))
      queue.zcard.should == 4
    end
  end

  describe "#pop" do
    before do
      [2, 1, -5].each_with_index do |ago, i|
        queue.push(items[i], Time.now + ago.minutes)
      end
    end

    it "should only pop items with a score less than the supplied score" do
      queue.push('1', 6)
      queue.push('4', 9)
      queue.push('9', 12)

      queue.pop(10).should == %w(1 4)
      queue.pop(10).should == []

      queue.pop(12).should == %w(9)
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
  end
end
