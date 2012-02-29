module SuperNode
  module Facebook
    class Batch

      attr_accessor :access_token, :batch, :queue_id
      attr_reader :callback

      def initialize(options = {})
        if options.present?
          setup options
        end
      end

      def setup(options)
        options.stringify_keys!

        options.slice(*%w(access_token batch queue_id)).each do |type, val|
          send(:"#{type}=", val)
        end
        @callback = SuperNode::Invocation.new(options['callback']) if options['callback'].present?

        verify!
      end

      def fetch(facebook_batch)
        setup facebook_batch # re-hydrate self with its attributes.

        SuperNode::HTTP.new(SuperNode::Facebook.base_url).post(to_batch)
      end

      def as_json(*)
        @as_json ||= {
          'queue_id' => queue_id,
          'access_token' => access_token,
          'batch' => batch,
        }
      end

      def to_invocation(*)
        @invocation ||= SuperNode::Invocation.new({
          'class' => self.class.name,
          'method' => 'fetch',
          'queue_id' => queue_id,
          'args' => [as_json],
        })
      end

      def to_batch(*)
        @to_batch ||= {
          'access_token' => access_token,
          'batch' => batch_json
        }
      end

      def batch_json
        @batch_json ||= batch.to_json
      end

      private

      def verify!
        raise ArgumentError, 'An Access Token is required' unless access_token.present?
        raise ArgumentError, 'A valid batch parameter is required' unless batch.presence && batch.any?
      end
    end
  end
end
