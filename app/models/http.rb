module SuperNode
  class HTTP
    
    def initialize(url)
      @uri = URI.parse(url)
    end

    def get
      http = prepare(Net::HTTP.new(@uri.host, 443))
      request = Net::HTTP::Get.new(@uri.request_uri)
      http.request(request)
    end

    def post(body = {})
      http = prepare(Net::HTTP.new(@uri.host, 443))
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.set_form_data(body) if body.present?
      http.request(request)
    end

    private

    def prepare(http, use_ssl = true)
      if use_ssl
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http
    end
  end
end
