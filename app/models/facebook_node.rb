module SuperNode
  class FacebookNode

    attr_accessor :access_token, :method, :relative_url, :body

    def initialize(options = {})
      if options.present?
        options['method'] = options['method'].try(:upcase) || 'GET'
        options['priority'] ||= "0"

        options.slice(*%w(access_token method relative_url body)).each do |type, val|
          send(:"#{type}=", val)
        end
      end
    end

    def to_json(*)
      ActiveSupport::JSON.encode({
        'created_at' => Time.now,
        'node' => to_node
      })
    end

    def to_node(*)
      node = {
        'relative_url' => relative_url,
        'method' => method,
      }
      node.merge!('access_token' => access_token) if access_token.present?
      node
    end

    def save
      raise SuperNode::ArgumentError, "A Facebook Relative URL is required. ie. 'me/feed' or :graph_id/comments" unless relative_url.present?
    end

    def self.from_json(json)
      JSON.parse(json)['node']
    end
  end
end