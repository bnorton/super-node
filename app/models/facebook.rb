module SuperNode
  class Facebook

    attr_accessor :graph_id, :access_token, :connection_type

    def initialize(options = {})
      options.slice(*%w(graph_id access_token connection_type)).each do |type, val|
        send(:"#{type}=", val)
      end
    end

    def save
      raise SuperNode::ArgumentError unless @graph_id && @access_token && @connection_type
    end
  end
end
