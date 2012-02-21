class App

  attr_accessor :access_token, :queue_id, :queue

  def initialize(options = {})
    options.stringify_keys!

    options.each do |k, v|
      send(:"#{k}=", v) rescue nil
    end

    @queue_id = "content:some"
    @access_token = 'AAACEdEose0cBANOgF34fo1McL66H05OfIjVumPkrvjziOXHNqAPdyLKV75YFVfYidTbOhtUBSNa2wZC3UTDYAChAUxofbM4MK9m26MQZDZD'
  end

  def go
    ##
    ## Setup the queue to pull items off the queue_id and
    ## batch the requests out to facebook
    ##

    facebook = SuperNode::Facebook.new({
      :queue_id => queue_id,
      :access_token => access_token,
    })
    
    queue = SuperNode::Queue.new({
      :invocation => facebook.to_invocation,
      :interval => 4,
      :queue_id => queue_id,
    })

    api = Koala::Facebook::API.new(access_token)
    ids = api.get_connections('me', 'friends').map {|f| f["id"]}
    nodes = ids.map {|i| SuperNode::FacebookNode.new({'relative_url' => "#{i}/feed"}) }
    nodes_json = nodes.map(&:to_json)

    queue.push(nodes_json)

    SuperNode::Worker.perform_async(facebook.to_invocation.to_json)

  end

  def self.completion(options = {})
    File.open(File.join(Rails.root, 'tmp', "app_#{Time.now.utc.to_s.gsub(' ', '-')}.txt"), 'w+') {|f| f.write("#{options.inspect}") }
  end
end

__END__

SuperNode::Worker.perform_async(SuperNode::Invocation.new({'class' => 'App', 'method' => 'go'}).to_json)





