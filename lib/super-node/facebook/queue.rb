module SuperNode
  module Facebook
    class Queue

      attr_accessor :queue_id, :access_token, :metadata

      def initialize(options = {})
        if options.present?
          setup options
        end
      end

      def setup(options)
        options.stringify_keys!

        options.slice(*%w(queue_id access_token metadata)).each do |type, val|
          send(:"#{type}=", val)
        end
      end

      # fetch takes a SuperNode::Facebook argument
      def fetch(facebook)

        File.open(File.join(Rails.root, 'tmp', "Fb.fetch.log"), 'a+') {|f| f.write("> #{Time.now.to_f} <") }

        setup facebook

        # Make an Invocation per batch and enqueue each in Sidekiq.
        batchify.each do |batch|
          batch.to_invocation.save
        end
      end

      # The Facebook Batch API is useful here
      #   See: `https://developers.facebook.com/docs/reference/api/batch/`
      # Pull all SuperNode::Facebook::Node(s) that were pushed up to now and
      # batchify them into as many workers as it takes.
      #
      def batchify
        now = Time.now.to_i
        nodes = nil

        Sidekiq::Client.redis.with do |r|
          nodes = r.zrangebyscore(queue_id, 0, now)
          r.zremrangebyscore(queue_id, 0, now)
        end

        batches = []
        nodes.in_groups_of(50, false) do |group|
          batches << SuperNode::Facebook::Batch.new({
            "access_token" => access_token,
            "queue_id" => queue_id,
            "batch" => group.map { |node| JSON.parse(node) },
          })
        end

        batches
      end

      def self.completion(options = {})
        raise "Facebook completion execption"

        #options['data'].body['data'].each do |data|
        #  redis.zadd(options['queue_id'], 2, data)
        #end
      end

      def to_json(*)
        {
          "queue_id" => queue_id,
          "access_token" => access_token,
          "metadata" => metadata,
        }
      end

      def to_invocation(*)
        SuperNode::Invocation.new({
          "class" => "SuperNode::Facebook::Queue",
          "method" => "fetch",
          "queue_id" => queue_id,
          "args" => [to_json]
        })
      end

      # Facebook Graph API URL
      def self.base_url
        "https://graph.facebook.com"
      end

      def queue_id
        @queue_id ||= 'sfq_default'
      end

      def self.url_from_paging(url)
        $1 if url =~ /https?\:\/\/graph\.facebook\.com\/(.+)/
      end

      # Facebook 'per-batch' limit
      def batch_size
        50
      end

      def save
        raise ArgumentError, "A Facebook Access Token is required" unless access_token.present?
      end
    end
  end
end
