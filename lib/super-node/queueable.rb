module SuperNode
  module Queueable

    # http://cheat.errtheblog.com/s/redis/
    # Redis API (LRANGE, LTRIM, LPOP, RPUSH)

    # RPUSH  - (key, value) Append value to the tail of the List value at key
    def push(inputs)
      inputs = [inputs] unless inputs.kind_of?(Array)

      inputs.each do |input|
        input = input.to_json unless input.kind_of?(String)
        redis.rpush(queue_id, input)
      end
    end

    # LRANGE - (key, start, end) Return a range of elements from the List at key
    # LTRIM  - (key, start, end) Trim the list at key to the specified range of elements
    # LPOP   - (key) Return and remove (atomically) the first element of the List at key
    def pop(count = 50)
      start, count = count <= 0 ? [-1, 1] : [0, count]
      items = []

      redis.with do |r| # redis MULTI/EXEC transaction
        items = r.lrange(queue_id, start, count - 1)
        r.ltrim(queue_id, count, -1)
      end

      items.map {|i| JSON.parse(i) rescue {} }
    end

    # LLEN - (key) Return the length of the List value at key
    def llen
      redis.llen(queue_id)
    end

    alias_method :length, :llen
    alias_method :count, :llen
    alias_method :size, :llen

    def redis
      Sidekiq.redis
    end
  end
end
