module SuperNode
  class Invocation
    # DEFAULTS = [:class, :method, :batch_id, :metadata]
    # 
    def initialize(options = {})
      @klass = options["class"]

      @method = options["method"].try(:to_sym) || :perform
      @batch_id = options["batch_id"]
      @metadata = options["metadata"]
      verify!
    end

    def save
      SuperNode::Queue.new(self).enqueue
    end

    def klass
      @klass
    end

    def method
      @method
    end

    def batch_id
      @batch_id
    end

    def metadata
      @metadata
    end

    private

    def verify!
      unless @klass.present? && (@klass = @klass.constantize rescue false) && @klass.respond_to?(@method)
        raise ArgumentError
      end
    end
  end
end