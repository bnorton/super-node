module SuperNode
  module PriorityQueueable
    def push(inputs, time = Time.now)
      inputs = [inputs] unless inputs.kind_of?(Array)

      inputs.each do |input|
        input = input.to_json unless input.kind_of?(String)
        redis.zadd(queue_id, time.to_i, input)
      end
    end

    def pop(time = Time.now, parse = true)
      time = time.to_i
      items = []

      redis.with do |r| # redis MULTI/EXEC transaction
        items = r.zrangebyscore(queue_id, 0, time)
        r.zremrangebyscore(queue_id, 0, time)
      end

      items.map! {|i| JSON.parse(i) rescue {} } if parse
      items
    end

    def zcard
      redis.zcard(queue_id)
    end

    alias_method :length, :zcard
    #alias_method :count, :zcard
    alias_method :size, :zcard

    def redis
      Sidekiq.redis
    end

  end
end