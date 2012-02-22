module SuperNode
  class HTTP
    
    def initialize(url)
      @uri = URI.parse(url)
    end

    def log(type = 'GET')
      time = Time.now
      File.open(File.join(Rails.root, 'log', 'http.log'), 'a+') {|f| f.write("#{type}: #{time} - ") }
      h = yield
      File.open(File.join(Rails.root, 'log', 'http.log'), 'a+') {|f| f.write("#{Time.now.to_f - time.to_f}\n") }
      h
    end

    def get
      http = prepare(Net::HTTP.new(@uri.host, 443))
      request = Net::HTTP::Get.new(@uri.request_uri)

      log do
        http.request(request)
      end
    end

    def post(body = {})
      http = prepare(Net::HTTP.new(@uri.host, 443))
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.set_form_data(body) if body.present?

      log('POST') do
        http.request(request)
      end
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
