module SuperNode
  class Invocation

    attr_accessor :klass, :method, :args, :queue_id, :metadata

    def initialize(options = {})
      options = JSON.parse(options) if options.kind_of?(String)
      options.stringify_keys!

      @klass = options['class']
      options['method'] = options['method'].try(:to_sym) || :perform

      options.slice(*%w(method args queue_id metadata)).each do |type, val|
        send(:"#{type}=", val)
      end

      verify!
    end

    def save
      SuperNode::Worker.new(self)
    end

    def as_json(*)
      hash = {
        'class' => klass.to_s,
        'method' => method.to_s,
        'args' => args,
      }
      hash.merge!('queue_id' => queue_id) if queue_id.present?
      hash.merge!('metadata' => metadata) if metadata.present?

      hash
    end

    private

    def verify!
      raise ArgumentError, 'A SuperNode::Invocation needs a target :class.' unless @klass.present?
      raise ArgumentError, "#{@klass} doesn't appear to be a valid constant." unless (@klass.constantize rescue false)
      @klass = @klass.constantize

      raise Exception, "A new instance of: #{@klass} didn't respond to: #{@method}" unless @klass.new.respond_to?(@method)
    end
  end
end
