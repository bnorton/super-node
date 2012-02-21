module SuperNode
  class Invocation

    attr_accessor :klass, :method, :args, :queue_id, :metadata

    def initialize(options = {})
      options = JSON.parse(options) if options.kind_of?(String)
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
      {
        "class" => klass.to_s,
        "method" => method,
        "args" => args,
        "queue_id" => queue_id,
        "metadata" => metadata,
      }
    end

    private

    def verify!
      raise ArgumentError, "A SuperNode::Invocatin needs a target 'class'." unless @klass.present?
      raise ArgumentError, "#{@klass} doesn't appear to be a valid constant." unless (@klass.constantize rescue false)
      @klass = @klass.constantize

      raise Exception, "Class: #{@klass} didn't respond to method: #{@method}" unless @klass.new.respond_to?(@method)
    end
  end
end
