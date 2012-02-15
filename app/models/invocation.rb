module SuperNode
  class Invocation

    attr_accessor :klass, :method, :bucket_id, :metadata

    def initialize(options = {})
      @klass = options["class"]
      options["method"] = options["method"].try(:to_sym) || :perform

      options.slice(*%w(method bucket_id metadata)).each do |type, val|
        send(:"#{type}=", val)
      end

      verify!
    end

    def save
      SuperNode::Worker.new(self).enqueue
    end

    def to_json(*)
      ActiveSupport::JSON.encode({
        "class" => klass.to_s,
        "method" => method,
        "bucket_id" => bucket_id,
        "metadata" => metadata
      })
    end

    private

    def verify!
      raise ArgumentError unless @klass.present? && (@klass = @klass.constantize rescue false) && @klass.respond_to?(@method)
    end
  end
end
