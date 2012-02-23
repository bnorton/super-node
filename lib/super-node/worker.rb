module SuperNode
  class Worker

    include Sidekiq::Worker

    attr_accessor :invocation

    def initialize(invocation = nil)

      if invocation.present?
        @invocation = invocation
        # Sidekiq::Client.push(invocation.queue_id, 'class' => 'SuperNode::Worker', 'args' => [invocation.to_json])
        Sidekiq::Client.push(nil, 'class' => 'SuperNode::Worker', 'args' => [invocation.to_json]) rescue nil
        # Sidekiq::Client.push('default', 'class' => 'SuperNode::Worker', 'args' => [invocation.to_json])
      end
    end

    # The Sidekiq client operates on SuperNode::Workers which operate, in turn
    #   on the invocation that is passed to it. This perform method will then
    #   make an invocation object from the json passed in and then go to work.
    def perform(invocation, options = {})
      invocation = SuperNode::Invocation.new(invocation)

      invocation.klass.new.send(invocation.method, *invocation.args)
    end
  end
end
