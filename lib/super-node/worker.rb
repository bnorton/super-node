module SuperNode
  class Worker
    include Sidekiq::Worker

    attr_accessor :invocation

    def initialize(invocation = nil)

      if invocation.present?
        @invocation = invocation
        Sidekiq::Client.push(nil, 'class' => 'SuperNode::Worker', 'args' => [@invocation.as_json]) rescue nil
      end
    end

    # The Sidekiq client operates on SuperNode::Workers. This perform method
    #   then performs the supplied invocation.
    def perform(invocation, options = {})
      invocation = SuperNode::Invocation.new(invocation)

      invocation.klass.new.send(invocation.method.to_sym, *invocation.args)
    end
  end
end
