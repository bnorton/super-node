module SuperNode
  class FacebookBatch

    attr_accessor :access_token, :batch, :queue_id

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
    end

    def save_delete(facebook_batch)

    end

    def fetch(facebook_batch)
      setup facebook_batch # re-hydrate self with its attributes.

      response = SuperNode::HTTP.new(SuperNode::Facebook.base_url).post(to_batch)

      File.open(File.join(Rails.root, 'tmp', "FbBatch.fetch.log"), 'a+') {|f| f.write("> #{Time.now.to_f * 1000} <") }

      App.completion({
        "queue_id" => queue_id,
        "data" => response,
        "data class" => response.body.class,
        "batch" => facebook_batch.inspect,
        "response" => JSON.parse(response.body).map{|m| JSON.parse(m["body"])}
      })
    end

    def to_json(*)
      @json ||= {
        "queue_id" => queue_id,
        "access_token" => access_token,
        "batch" => batch,
      }
    end

    def to_invocation(*)
      @invocation ||= SuperNode::Invocation.new({
        "class" => "SuperNode::FacebookBatch",
        "method" => "fetch",
        "queue_id" => queue_id,
        "args" => [to_json],
      })
    end

    def to_batch(*)
      {
        "access_token" => access_token,
        "batch" => batch_json
      }
    end

    def batch_json
      ActiveSupport::JSON.encode(batch)
    end
  end
end