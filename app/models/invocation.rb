module SuperNode
  class Invocation

    attr_accessor :klass, :method, :args, :queue_id, :metadata

    def initialize(options = {})
      @klass = options["class"]
      options["method"] = options["method"].try(:to_sym) || :perform

      options.slice(*%w(method args queue_id metadata)).each do |type, val|
        send(:"#{type}=", val)
      end
      verify!
    end

    def save
      SuperNode::Worker.new(self)
    end

    def to_json(*)
      ActiveSupport::JSON.encode({
        "class" => klass.to_s,
        "method" => method,
        "args" => args,
        "queue_id" => queue_id,
        "metadata" => metadata,
      })
    end

    private

    def verify!
      raise SuperNode::ArgumentError, "A SuperNode::Invocatin needs a target 'class'." unless @klass.present?
      raise SuperNode::ArgumentError, "#{@klass} doesn't appear to be a valid constant." unless (@klass = @klass.constantize rescue false)
      raise SuperNode::MethodNotFound, "Class: #{@klass} didn't respond to method: #{@method}" unless @klass.new.respond_to?(@method)
    end
  end
end
