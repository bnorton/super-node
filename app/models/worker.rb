module SuperNode
  class Worker

    include Sidekiq::Worker

    def initialize(invocation = nil)
      if invocation.present?
        # this might be the place for the invocation to be pushed
        Sidekiq::Client.push(invocation.bucket_id, 'class' => 'SuperNode::Worker', 'args' => [invocation.to_json])
      else
        # We have been invoked for processing
        #   could be the place to re-enqueue the job.
      end
    end

    # The perform method makes the supplied invocation and 
    # makes the callback to the, you guessed it, callback_url for this bucket.
    def perform(invocation, options = {})
      # The Sidekiq client operates on SuperNode::Workers which operate, in turn
      #   on the invocation that is passed to it. This perform method will then
      #   make an invocation object from the json passed in and then go to work.
      # 
      #   SuperNode::Invocation.new(invocation)
      #   ## Then perform the inovcation
      #
      # Sidekiq::Client.push(bucket_id, 'class' => 'SuperNode::Worker', 'args' => [*invocation.to_json])
      # Sidekiq::Client.push('queue_name', {'class' => name, 'args' => ['foo', ]})
    end

    def enqueue
    end
  end
end
