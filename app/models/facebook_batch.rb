module SuperNode
  class FacebookBatch

    attr_accessor :access_token, :batch, :metadata, :queue_id

  def self.log(what)
    @log ||= Logger.new(STDERR)
    @log.level ||= Logger::INFO
    @log.debug what
  end


    def initialize(options = {})
      if options.present?
        setup options
      end
    end

    def setup(options)
      options.slice(*%w(access_token batch queue_id)).each do |type, val|
        send(:"#{type}=", val)
      end
    end

    def fetch(facebook_batch)
      options = JSON.parse(facebook_batch)
      setup options # re-hydrate self with its attributes.

      response = SuperNode.HTTP.new(base_url).post(to_batch)

      SuperNode::Facebook.completion({
        "queue_id" => queue_id,
        "metadata" => metadata,
        "data" => response,
      })
    end

    def to_json(*)
      ActiveSupport::JSON.encode({
        "queue_id" => queue_id,
        "access_token" => access_token,
        "metadata" => metadata,
        "batch" => batch,
      })
    end

    def to_invocation(*)
      SuperNode::Invocation.new({
        "class" => "SuperNode::FacebookBatch",
        "method" => "fetch",
        "queue_id" => queue_id,
        "args" => [to_json],
      })
    end

    def to_batch(*)
      ActiveSupport::JSON.encode({
        "access_token" => access_token,
        "batch" => batch
      })
    end

  end
end
