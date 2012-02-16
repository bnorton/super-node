module SuperNode
  class Facebook < SQueue

    attr_accessor :bucket_id, :access_token, :interval

    # When Sidekiq is preparing the SuperNode::Facebook object for processing
    #   it calls `new` with not arguments.
    def initialize(options = {})
      if options.present?
        options['interval'] = options['interval'].to_i || 60 * 5 # 5 minutes

        options.slice(*%w(bucket_id access_token interval)).each do |type, val|
          send(:"#{type}=", val)
        end
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
        batches << {
          "access_token" => access_token,
          "batch" => fbnodes
        }
      end

      batches
    end

    def queue_id
      return "sfq_default" if bucket_id.blank?
      "sfq_#{bucket_id}"
    end

    def base_url
      "https://graph.facebook.com"
    end

    def batch_size
      50
    end

    def save
      raise SuperNode::ArgumentError, "A Facebook Access Token is required" unless access_token.present?
    end
  end
end
