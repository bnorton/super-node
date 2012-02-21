module SuperNode
  class Facebook < SQueue

    attr_accessor :queue_id, :access_token, :metadata

    # When Sidekiq is preparing the SuperNode::Facebook object for processing
    #   it calls `new` with not arguments.
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
      
      @queue_id = "sfq_default" if @queue_id.blank?
    end

    # fethc takes a SuperNode::Facebook argument
    def fetch(facebook)

      File.open(File.join(Rails.root, 'tmp', "Fb.fetch.log"), 'a+') {|f| f.write("> #{Time.now.utc} <") }

      setup facebook

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
        nodes = redis.zrangebyscore(queue_id, 0, now)
        redis.zremrangebyscore(queue_id, 0, now)
      end

      File.open(File.join(Rails.root, 'tmp', "fb_nodes-#{now}"), 'w+') {|f| f.write(nodes.inspect) }

      batches = []
      nodes.in_groups_of(50, false) do |group|
        batches << SuperNode::FacebookBatch.new({
          "access_token" => access_token,
          "queue_id" => queue_id,
          "batch" => group,
        })
      end

      batches
    end

    def self.completion(options = {})
      File.open(File.join(Rails.root, 'tmp', "fb_#{Time.now.utc.to_s.gsub(' ', '-')}.txt"), 'w+') {|f| f.write("#{options.inspect}") }
      options['data'].body['data'].each do |data|
        redis.zadd(options['queue_id'], 2, data)
      end
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
        "class" => "SuperNode::Facebook",
        "method" => "fetch",
        "queue_id" => queue_id,
        "args" => [to_json]
      })
    end

    def queue_id
      @queue_id ||= 'sfq_default'
    end

    # Facebook Graph API URL
    def self.base_url
      "https://graph.facebook.com"
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