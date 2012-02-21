module SuperNode
  class Bucket < ::SQueue

    attr_accessor :bucket_id, :callback_url

    def self.find_or_create_by_bucket_id(options = {})
      if (_id = options['bucket_id']).present? && (bucket = redis.get(_id)).present?
        SuperNode::Bucket.new(JSON.parse(bucket))
      else
        SuperNode::Bucket.new(options)
      end
    end

    def initialize(options = {})
      options.stringify_keys!

      options.slice(*%w(bucket_id callback_url)).each do |type, val|
        send(:"#{type}=", val)
      end

      verify!
      set(self.bucket_id, ActiveSupport::JSON.encode(to_json))
    end

    def queue_id
      "siq_#{bucket_id}"
    end

    def to_json(*)
      {
        "bucket_id" => bucket_id,
        "callback_url" => callback_url,
      }
    end

    private

    def bucket_id?
      bucket_id.present?
    end

    def callback_url?
      callback_url.present?
    end

    def verify!
      raise ArgumentError, "Bucket ID cannot be blank." unless bucket_id?
      raise ArgumentError, "Callback URL cannot be blank" unless callback_url?
    end
  end
end
