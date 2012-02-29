module SuperNode
  module Facebook
    class Node

      attr_accessor :access_token, :method, :relative_url, :body
      attr_accessor :code, :data

      attr_reader :pagination, :next_page, :previous_page

      def initialize(options = {}, response = {})
        if options.present?
          setup options, response
        end

        verify!
      end

      def setup(options, response)
        options.stringify_keys!
        options['method'] = options['method'].try(:upcase) || 'GET'

        options.slice(*%w(access_token method relative_url body)).each do |type, val|
          send(:"#{type}=", val)
        end

        if response.present?
          parse! response
        end

      end

      def parse!(response)
        body = JSON.parse(response['body'])

        @code = response['code']
        @data = body['data']
        paginate! body['paging']
      end

      def paginate!(paging)
        return if paging.blank?
        @pagination ||= {
          'next_page' => {
            'access_token' => access_token,
            'relative_url' => SuperNode::Facebook::Queue.url_from_paging(paging['next']),
            'method' => 'GET',
          },
          'previous_page' => {
            'access_token' => access_token,
            'relative_url' => SuperNode::Facebook::Queue.url_from_paging(paging['previous']),
            'method' => 'GET',
          }
        }
      end

      def next_page
        @next_page ||= SuperNode::Facebook::Node.new(@pagination['next_page'])
      end

      def previous_page
        @previous_page ||= SuperNode::Facebook::Node.new(@pagination['previous_page'])
      end

      def as_json(*)
        to_node
      end

      def to_node(*)
        node = {
          'relative_url' => relative_url,
          'method' => method,
        }
        node.merge!('body' => body) if body.present?
        node.merge!('access_token' => access_token) if access_token.present?
        node
      end

      def save
        raise ArgumentError, "A Facebook Relative URL is required. ie. 'me/feed' or :graph_id/comments" unless relative_url.present?
      end

      def verify!
        # TODO move save to here
      end
    end
  end
end

__END__

# code is an integer
# body.data is still a JSON encoded string

The Node that is passed to the parse! method will be the response from facebook

A SuperNode::Facebook::Node should represent this object
{
  "code"=>200,
  "headers"=> [
    {"name"=>"Cache-Control", "value"=>"private, no-cache, no-store, must-revalidate"},
    {"name"=>"ETag", "value"=>"\"1050253aec7b29caff644806927dabfa81406eee\""}, 
    {"name"=>"Expires", "value"=>"Sat, 01 Jan 2000 00:00:00 GMT"}, 
  ],
  "body"=>"{\"data\":[{\"id\":\"100002518620011_206472486113371\",\"from\":{\"name\":\"Shannon Forbes\",\"id\":\"100002518620011\"},\"story\":\"Shannon Forbes and Kristyn Brigance are now friends.\",\"story_tags\":{\"19\":[{\"id\":9621125,\"name\":\"Kristyn Brigance\",\"offset\":19,\"length\":16}],\"0\":[{\"id\":100002518620011,\"name\":\"Shannon Forbes\",\"offset\":0,\"length\":14}]},\"type\":\"status\",\"created_time\":\"2012-01-10T17:21:59+0000\",\"updated_time\":\"2012-01-10T17:21:59+0000\",\"comments\":{\"count\":0}}]}"
}

The paging item in the response looks like this (for `nike/feed`)

"paging": {
    "previous": "https://graph.facebook.com/nike/feed?format=json&limit=25&since=1329839041&__previous=1", 
    "next": "https://graph.facebook.com/nike/feed?format=json&limit=25&until=1327531370"
  }
