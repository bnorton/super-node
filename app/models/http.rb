module SuperNode
  class HTTP
    
    def initialize(url)
      @uri = URI.parse(url)
    end

    def post(body = {})
      http = Net::HTTP.new(@uri.host, 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.set_form_data(body) if body.present?
      http.request(request)
    end
  end
end
