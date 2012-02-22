module SuperNode
  class Queue

    attr_accessor :invocation, :interval, :queue_id

    def initialize(options = {})
      setup options unless options.blank?
    end

    def setup(options)
      options.stringify_keys!

      options.slice(*%w(invocation interval queue_id)).each do |type, val|
        send(:"#{type}=", val)
      end
    end

    def push(inputs, time = Time.now)
      inputs = [inputs] unless inputs.kind_of?(Array)
      items = []

      inputs.each do |input|
        input = ActiveSupport::JSON.encode(input) unless input.kind_of?(String)
        redis.zadd(queue_id, time.to_i, input)
      end
    end

    def pop(time = Time.now)
      time = time.to_i
      items = []

      redis.with do |r| # redis MULTI/EXEC
        items = r.zrangebyscore(queue_id, 0, time)
        r.zremrangebyscore(queue_id, 0, time)
      end

      items.map {|i| JSON.parse(i) rescue {} }
    end

    def zcard
      redis.zcard(queue_id)
    end

    alias_method :length, :zcard
    alias_method :count, :zcard
    alias_method :size, :zcard

    def perform(queue = {})
      setup queue # rehydrate this object from the

      at_inverval
    end

    def at_inverval(exit = false)
      count = 0

      loop do
        before = Time.now.to_f

        SuperNode::Invocation.new(invocation).save

        # At each interval pop all items that are
        #  scheduled to run now or before and invoke them
        # pop.each do |invocation|
        #   SuperNode::Invocation.new(invocation).save
        # end

        return if exit

        sleep(interval - (Time.now.to_f - before))

        count += 1
      end
    end

    def to_invocation
      {
        'class' => 'SuperNode::Queue',
        'method' => 'perform',
        'args' => [to_json]
      }
    end

    def to_json
      {
        'invocation' => invocation.to_json,
        'interval' => interval,
        'queue_id' => queue_id
      }
    end

    private

    def redis
      Sidekiq::Client.redis
    end
  end
end
