module SuperNode

  class MethodNotFound < Exception; end
  class ArgumentError < ArgumentError; end

  def self.perform
  end

  def self.verify!(options = {})
    return false unless options["callback_url"]
    response = SuperNode::HTTP.new(options["callback_url"]).post
    puts response.inspect
    response.code == "200"
  end
end