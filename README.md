#Super Node is for fetching content.

####Objectives and Goals:
The goal of the Super Node project is to provide a decoupled architecture for performing
and parsing asynchronous HTTP requests.

####Technical details:
The internal queueing structure accomplishes two goals:

1. Maximizes the amount of and timeliness of data.
2. Decouples HTTP requests from any storage/business logic.

Has multiple levels of priority queues that can maintain a strict SLA of content delivery.

##Core concepts
- Invocation: An abstract method call. An Invocation is fully specified by the `class`, `method` and `args`.


##Creating the Global Processing Queue
#####Every application has a single `SuperNode::Queue` object which manages all content. Each item on said queue is a `SuperNode::Invocation`.

###Examples
====
- A SuperNode::Queue is initialized with any number of :invocation and :interval pairs.
- Each invocaiton will be invoked on a distinct processing thread at the specified interval.

#####Posted Content needs to send data frequently; ie. every 5 seconds, and fetched content should happen no less frequent than every minute.

```ruby
SuperNode::Queue.new(
  {
    :interval => 5,
    :invocation => SuperNode::Invocation.new({
      :class => 'SuperNode::Facebook::Batch',
      :method => 'save_delete',
      :args => [{
        :access_token => 'AEFARf33fas..',
        :queue_id => 'content:save_delete:all'
      }]
    }),
  },
  { 
    :interval => 60,
    :invocation => ...,
  }
)
```

##Parsing and Processing content
This is the hook back into your application's storage and processing logic.

It is highly recommended that the parsing and processing of content _not_ happen in the same invocation that fetches content. (Time based prioritzation of HTTP requests may become inaccurate).
The best way to decouple maintain a decoupled content fetch model is a _shared_ processing queue. Have your `fetch` and `save` invocaitons place the returned data into Redis on an agreed-upon location (such as `queue_id + ':parse'` OR an argument to the invocation)

####`include SuperNode::Queuable` (TODO) since most of the able is alread implemented.

####To parse content as it returns, implement a `SuperNode::Invocation` and pass that to the `SuperNode::Queue.new` as the `:callback` parameter. (see above)

####Example
#####Custom Parse method Invocation object

```ruby
SuperNode::Invocation.new({
  :class => 'FacebookContent',
  :method => 'parse',
  :args => [{'parse_queue' => 'content:fetch:all:parse'}]
})}
...
class FacebookContent
  include SuperNode::Queuable

  def parse(options = {})
    puts options['parse_queue']
    #=> 'content:fetch:all:parse'
    items = pop(options['parse_queue'])
  end
end
```

##Facebook Plugin (WIP)
====
When used as the exclusive connector to Facebook, _guarantees_ that you will stay within the rate-limit. 

Using the Super-Node plugin (currently integrated by default) for Facebook you can `fetch`, `save`, `delete` and later `parse`.

- `fetch`, `save`, and `delete` are buffered and batched for more efficient use of resources and Facebook rate limit.

- `parse` is the the buffered callback into your application for processing results. The parse method will need to be general enough to process any of the above results (see `SuperNode::Invocation`).

A Node refers to an entity of the Facebook graph of entities and connections.
##Examples
====

- `:access_token` - the token that has the right permissions for the action.
- `:graph_id` - always the parent entity in a connection. A new Facebook Post has the includes the :graph_id of the Facebook Page to which the Post is going to. A new Facebook comments includes the :graph_id of the Facebook Post to which the comment is targeted.
- `:metadata` - Any extra data (mostly internal identifiers) that you will need to process the Node in the parse callback. Note: this data is _not_ sent to Facebook.

###Creating New Post on a Wall
- `:graph_id` - of the Facebook Page to post to

```ruby
SuperNode::Facebook::Node.new({
  :access_token => 'AAACEdEo..',
  :graph_id => '29fs2sds3d93..',
  :message => 'This is my wall, hope you like it.',
  :metadata => { :page_id => 102376, :user_id => 3203 }
}).save
```

###Example - Creating a New Comment
- `:graph_id` - of the message to create a comment about

```ruby
SuperNode::Facebook::Node.new({
  :access_token => 'AAACEdEo..',
  :graph_id => '23d93sds29fs..',
  :message => 'This is a comment.',
  :metadata => { :page_id => 102376, :user_id => 3203 }
}).save
```

####Example - Deleting a Facebook Post
- `:graph_id` - of the message/comment that is to be deleted

```ruby
SuperNode::Facebook::Node.new({
  :access_token => 'AAACEdEo..',
  :graph_id => '23d93sds29fs..',
  :metadata => { :page_id => 102376, :user_id => 3203 }
}).delete
```

##Fetching content
###To fetch content, create a new `SuperNode::Facebook::Node` and call `fetch`

####Example
#####Fetch page information for a Page/User/Message/Comment
The default `:connection` is blank. Therefore the generated URL is ...graph.facebook.com/:graph_id, which gets you the information about a Facebook Graph Node associated with the `:graph_id`.

```ruby
SuperNode::Facebook::Node.new({
  :access_token => 'AAf3lkeq34..',
  :graph_id => '23d93sds29fs..',
  :metdata => { :page_id => 102376, :user_id => 3203 }
}).fetch
```

####Example
#####Pull down comments for a public message (no access_token required)
The `:connection` parameter to the fetch method is to specify what connections you are fetching.
Therefore the generated URL is ...graph.facebook.com/:graph_id/:connection, which gets you the comments on the Facebook Graph Node associated with the `:graph_id`.

```ruby
SuperNode::Facebook::Node.new({
  :graph_id => '29fsd9233sdl..',
  :metdata => { :page_id => 102376, :user_id => 3203 }
}).fetch(:connection => 'comments')
```

##Monitoring (TODO)
The default behavior of any of the `fetch` operations is simply that, a `fetch`. However when initializing a new Facebook Page or Facebook User on SuperNode, you can turn `fetch` into `monitor`, which will keep old content up-to-date (like-counts, comments, etc.) and will pull new content when published. To enable this pass an additional parameter, `:monitor` which should have a value of true

- When a Facebook Page is in monitoring mode:

1. The most recent 15 Posts will be updated for metadata, comments and like-count. This is the highest prioirty (monitor) queue.
2. The 50 most recent comments (on a post) are tracked for like-count.

A valid request to the batch API has a top-level "access_token" and a top-level "batch" parameter. The "batch" parameter needs to be JSON encoded.

{
  "access_token": "AAACEdE..",
  "batch": 
  [
    { `node` },
    { `node` }
  ]
}

A valid response from Facebook has three components
- The body of the response is a JSON encoded array of the batched requests (in order).
- Each of the array items takes the form of what a 'normal' request would give you as far as information goes. Top-level keys are `code`, `headers`, `body`
- The body is the SAME as any other request to the graph, one more level of JSON encoded

JSON.parse(response.body).map{ |u| u['body'] } # is the array of graph API responses.

