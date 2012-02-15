module SuperNode
  class Bucket

    attr_accessor :bucket_id, :callback_url

    def self.find_or_create_by_bucket_id(options = {})
      if (_id = options['bucket_id']) && (bucket = redis.get(_id))
        SuperNode::Bucket.new(JSON.parse(bucket))
      else
        SuperNode::Bucket.new(options)
      end
    end

    def self.exists?(id)
      redis.exists(id)
    end

    def initialize(options = {})
      options.slice(*%w(bucket_id callback_url)).each do |type, val|
        send(:"#{type}=", val)
      end

      verify!
      self.class.redis.set(self.bucket_id, to_json)
    end

    def to_json(*)
      ActiveSupport::JSON.encode({
        "bucket_id" => bucket_id,
        "callback_url" => callback_url
      })
    end

    private

    def bucket_id?
      bucket_id.present?
    end

    def callback_url?
      callback_url.present?
    end

    def verify!
      raise ArgumentError unless bucket_id? && callback_url?
    end

    def self.redis
      Sidekiq::Client.redis
    end
  end
end
