module SuperNode
  def self.perform
  end

  def self.verify!(options = {})
    return false unless (url = options["callback_url"])
    SuperNode::HTTP.new(url).post.code == "200"
  end
end
