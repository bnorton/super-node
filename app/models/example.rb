class Example
  def fetch
    facebook = SuperNode::Facebook::Queue.new({
      :queue_id => queue_id,
      :access_token => access_token,
    })
    
    queue = SuperNode::Queue.new({
      :invocation => facebook.to_invocation,
      :interval => 5,
      :queue_id => queue_id,
    })

    ids = JSON.parse(File.read(File.join(Rails.root, 'tmp', 'ids.txt')))
    nodes_json = ids.map {|i| SuperNode::Facebook::Node.new({:relative_url => "#{i}/comments?limit=300"}).to_node }
    
    queue.push(nodes_json)

    SuperNode::Worker.perform_async(facebook.to_invocation.as_json)

  end

  def self.run
    invocation = SuperNode::Invocation.new({ :class => 'Example', :method => 'fetch' })

    queue = SuperNode::Queue.new({
      :invocation => invocation.as_json,
      :interval => 5
    }).to_invocation.as_json

    SuperNode::Worker.perform_async(queue)
  end
end
