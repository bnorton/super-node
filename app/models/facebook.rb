module SuperNode
  class Facebook < SQueue

    attr_accessor :bucket_id, :access_token, :metadata, :interval

    # When Sidekiq is preparing the SuperNode::Facebook object for processing
    #   it calls `new` with not arguments.
    def initialize(options = {})
      if options.present?
        setup options
      end
    end

    def setup(options)
      options['interval'] = options['interval'].to_i || 60 * 5 # 5 minutes

      options.slice(*%w(bucket_id access_token metadata interval)).each do |type, val|
        send(:"#{type}=", val)
      end

    end

    # enqueue takes a SuperNode::Facebook argument
    def enqueue(facebook)
      setup JSON.parse(facebook)

      # Make an Invocation per batch and enqueue each in Sidekiq.
      batchify.each do |batch|
        batch.to_invocation.save
      end
    end

    # The Facebook Batch API is useful here
    #   See: `https://developers.facebook.com/docs/reference/api/batch/`
    # Pull all SuperNode::FacebookNode(s) that were pushed up to now and
    # batchify them into as many workers as it takes.
    #
    def batchify
      now = Time.now.to_i
      nodes = nil

      multi do |redis|
        nodes = redis.zrange(queue_id, 0, now)
        redis.zremrangebyscore(queue_id, 0, now)
      end

      facebook_nodes = nodes.map do |node|
        SuperNode::FacebookNode.from_json(node)
      end

      batches = []
      facebook_nodes.in_groups_of(50, false) do |fbnodes|
        batches << SuperNode::FacebookBatch.new({
          "access_token" => access_token,
          "metadata" => metadata,
          "queue_id" => queue_id,
          "batch" => fbnodes,
        })
      end
      batches
    end

    def self.completion(options = {})
      options['data'].each do |data|
        redis.zadd(options['queue_id'], 2, data)
      end
    end

    def to_json(*)
      ActiveSupport::JSON.encode({
        "bucket_id" => bucket_id,
        "access_token" => access_token,
        "metadata" => metadata,
        "interval" => interval,
      })
    end

    def to_invocation(*)
      SuperNode::Invocation.new({
        "class" => "SuperNode::Facebook",
        "method" => "enqueue",
        "queue_id" => queue_id,
        "args" => [to_json]
      })
    end

    # What queue we find ourselves on
    def queue_id
      return "sfq_default" if bucket_id.blank?
      "sfq_#{bucket_id}"
    end

    # Facebook Graph API URL
    def base_url
      "https://graph.facebook.com"
    end

    # Facebook 'per-batch' limit
    def batch_size
      50
    end

    def save
      raise SuperNode::ArgumentError, "A Facebook Access Token is required" unless access_token.present?
    end
  end
end
