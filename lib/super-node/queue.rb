module SuperNode
  class Queue

    include SuperNode::Queueable

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

    # This method is the run loop that pulls items off registered 
    #   queues after their scheduled time and invokes them
    # Exit condition: when "#{queue_id}:exit" is set in redis
    def perform(queue = {})
      setup queue unless queue.blank? # rehydrate this object (called from a sidekiq worker)
      count = 0

      loop do
        before = Time.now.to_f
        SuperNode::Invocation.new(invocation).save

        break if exit?(count)

        sleep(interval - (Time.now.to_f - before))
        count += 1
      end
    end

    def exit?(count = 0)
      !!redis.get("#{queue_id}:exit") || count > 10
    end

    def to_invocation(*)
      SuperNode::Invocation.new({
        :class => 'SuperNode::Queue',
        :method => 'perform',
        :args => [as_json],
      })
    end

    def as_json(*)
      {
        'invocation' => invocation.as_json,
        'interval' => interval,
        'queue_id' => queue_id,
      }
    end
  end
end
