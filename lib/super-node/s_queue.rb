# Base class for all SuperNode Queueable Items
#   provides default functionality for adding and
#   removing items from the various queues.

class SQueue
  def length
    redis.llen(queue_id)
  end

  def push(item)
    redis.lpush(queue_id, item.to_json)
  end

  def pop
    redis.rpop(queue_id)
  end

  def set(*args)
    redis.set(*args)
  end

  # pop all items that were queued before some time.
  def pop_until(time)
    # redis.
  end

  # The default queue_id for all Queueable Classes
  #   (SuperNode Invocation Queue - Default)
  def queue_id
    "siq_default"
  end

  def process_queue_id
    "#{queue_id}_process"
  end

  def multi
    redis.with do |r|
      yield r
    end
  end

  def redis
    self.class.redis
  end

  # Queue Class Methods
  class << self
    def redis
      Sidekiq::Client.redis
    end

    def exists?(id)
      redis.exists(id)
    end
  end
end