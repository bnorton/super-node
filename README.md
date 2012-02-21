#Super Node is for fetching content.

##Facebook
====

Using the Super Node plugin for Facebook you can `fetch`, `save`, `delete` and later `parse`.
- `fetch`, `save`, and `delete` are buffered and batched for more efficient use of resources and Facebook rate limit.
- `parse` is the the buffered callback into your application for processing results. The parse method will need to be general enough to process any of the above results (see `SuperNode::Invocation`).

A Node refers to an entity of the Facebook graph of entities and connections.
##Examples
====

- :access_token - the token that has the right permissions for the action.
- :graph_id - always the parent entity in a connection. A new Facebook Post has the includes the :graph_id of the Facebook Page to which the Post is going to. A new Facebook comments includes the :graph_id of the Facebook Post to which the comment is targeted.
- :metadata - Any extra data (mostly internal identifiers) that you will need to process the Node in the parse callback. Note: this data is _not_ sent to Facebook.

###Creating New Post on a Wall
- :graph_id - of the Facebook Page to post to

```javascript
SuperNode::Facebook::Node.new({
  :access_token => 'AAACEdEo..',
  :graph_id => '29fs2sds3d93..',
  :message => 'This is my wall, hope you like it.',
  :metadata => { :page_id => 102376, :user_id => 3203 }
}).save
```

###Example - Creating a New Comment
- :graph_id - of the message to create a comment about

```javascript
SuperNode::Facebook::Node.new({
  :access_token => 'AAACEdEo..',
  :graph_id => '23d93sds29fs..',
  :message => 'This is a comment.',
  :metadata => { :page_id => 102376, :user_id => 3203 }
}).save
```

####Example - Deleting a Facebook Post
- :graph_id - of the message/comment that is te be deleted

```javascript
SuperNode::Facebook::Node.new({
  :access_token => 'AAACEdEo..',
  :graph_id => '23d93sds29fs..',
  :metadata => { :page_id => 102376, :user_id => 3203 }
}).delete
```

##Creating a new Processing Queue
###Examples
====
- :invocation - `:method` will be called on `:class` with `:args`) at the specified interval.
- :interval - Maximum Time in-between a batch call.
- :queue_id - unique id.
- :default - Array of request types that this queue processes.

####Example - Creating a new Queue.
#####Posted Content needs to send data frequently; ie. every 4 seconds.

```javascript
SuperNode::Queue.new({
  :invocation => SuperNode::Invocation.new({
    :class => 'SuperNode::FacebookBatch',
    :method => 'save_delete',
    :args => [{
      :access_token => 'AEFARf33fas..',
      :queue_id => 'content:save_delete:all'
    }]
  }),
  :interval => 4,
  :queue_id => 'content:save_delete:all',
  :default => [:save, :delete]
})
```

####Fetched content needs to update frequently when first posted then less frequently for a while after.
- When multiple intervals are specified (an array), a queue for each will be created. Recent content will tend to stay on the most frequently updated queue. Less active content will rotate onto the less frequently updated queues. This means that content that is active for a long period of time will continue to be update frequently.

```javascript
SuperNode::Queue.new({
  :access_token => 'AEFARf33fas..',
  :interval => [30, 300, 1800, 3600]
  :queue_id => 'content:fetch:all',
  :default => [:fetch]
})
```

####Fetch content _now_ Queue
If this operation requires miltiple levels of connections such as comments on messages, construct a chain of callbaks and and enqueues that allows each fetch to be batched along with others.

```javascript
SuperNode::Queue.new({
  :access_token => 'AEFARf33fas..',
  :interval => 0,
  :queue_id => 'content:fetch:now'
})
```

##Parsing and Processing content
###To parse content as it returns, implement a `SuperNode::Invocation` for each action, and add a param with the action name and invocation to the `SuperNode::Queue.new`
- Actions
1. `parse`
2. TODO `{before, after}_parse`

####Example
#####Custom Parse method Invocation object
Pass the option `:parse` to the Queue create and this will be called when data is ready.
This is the hook back into your application.
Any arbitrary method can be specified here since an Invocation is effectively a function pointer.
The arguments to the is method are _always_ the same; An Array of `SuperNode::Facebook::Node`s
See the section of `SuperNode::Facebook:Node` for more information.

```javascript
SuperNode::Invocation.new({
  :class => 'FacebookContent',
  :method => 'parse'
})}
```

##Fetching content
###To fetch content, create a new `SuperNode::Facebook:Node` and call `fetch`

####Example
#####Fetch page information for a Page/User/Message/Comment
The default `:connection` is blank. Therefore the generated URL is ...graph.facebook.com/:graph_id, which gets you the information about a Facebook Graph Node associated with the `:graph_id`.

```javascript
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

```javascript
SuperNode::Facebook::Node.new({
  :graph_id => '29fsd9233sdl..',
  :metdata => { :page_id => 102376, :user_id => 3203 }
}).fetch(:connection => 'comments')
```

##Monitoring
The default behavior of any of the `fetch` operations is simply that, a `fetch`. However when initializing a new Facebook Page or Facebook User on SuperNode, you can turn `fetch` into `monitor`, which will keep old content up-to-date (like-counts, comments, etc.) and will pull new content when published. To enable this pass an additional parameter, `:monitor` which should have a value of true

- When a Facebook Page is in monitoring mode:

1. The most recent 15 Posts will be updated for metadata, comments and like-count. This is the highest prioirty (monitor) queue.
2. The 50 most recent comments (on a post) are tracked for like-count.

##Objectives and Goals:
The goal of the internal queueing structure is to maximize the amount of and timeliness of data, while staying withing the rate limit and maximizing the effectiveness of workers.






#Super Node

##An Asynchronous background queue that is accessable via a simple API.

There are two main way ways to request data from from Super Node.
- The easiest way is to prefix `async_` to the beginning of a method invocation.
When a function is `User.send_email` then just call `User.async_send_email` with the same arguments as before.
- The other way is to `POST` to `/enqueue` with an `invocation` object.

#####Request endpoints
- `POST` to `/enqueue`

#/enqueue

####use to add a request to a queue

#####Required paramteters:
- `token` - This random string that will serve to verify the authenticity of the request. This field is mirrored upon response.
- `invocation` - A hash of the stringified invocation.

#####Optional parameters:
- `data` - A hash of identifying data. This field is mirrored upon response.
- `bucket_id` - A unique identifier for bucket that requests will be processed from. Defaults to the 'primary' batch

#####Sample request:
######Performs the Invocation as `Fetcher.perform("/me", { "access_token": "g903jDJa", .. })`
```javascript
  {
    "token": "AAf3lkeq34..",
     "data": { "account_id": 7, .. },
     "invocation": {
       "class": "Fetcher",
       "method": "perform",
       "params": ["/me", { "access_token": "g903jDJa", .. }]
     }
  }
```


####When a Batch Completes
######Super Node `POST`s to the `callback_url` with a JSON hash.
- `code` - The status of the response.
- `token` - Mirrored from the request.
- `metadata` - Mirrored from the request.
- `data` - The list of items returned from the batch request.

#####(A). Sample success:
```javascript
  {
    "code": 200,
    "bucket_id": "JS2s0yw93dj",
    "metadata": { "account_id": 7, "type": "FacebookPost", .. },
    "data": [
      { ..(B).. },
    ]
  }
```

#####(A). Sample error:
```javascript
  {
    "code": 401,
    "bucket_id": "JS2s0yw93dj",
    "metadata": { "account_id": 7, .. },
    "data": []
  }
```

#####(B). Sample 'data item':
Each item from the list of data items in (A) is of type (B).

```javascript
  {
    "code": 200,
    "token": "AAf3lkeq34.."
    "metadata": { },
    "response": { }
  }
```

##/batch

####use to create a new batch (bucket)

#####Required parameters:
- `callback_url` - The url that will be `POST`ed to upon response.
- `bucket_id` - The unique identifier for this bucket.

#####Optional parameters:
- `batch_timeout` - Number of miliseconds between commits
- `metadata` - Some extra information about the batch. Mirrored

#####Sample batch creation
that the server is ready to accept connections.
```javascript
  {
    "callback_url": "https://10.10.203.4/messages/callback.json",
    "bucket_id": "AAf3lkeq34..",
    "metadata": { .. },
    "batch_timeout": 60000
  }
```

#####Upon creating the batch:
Super Node will `POST` to the callback_url to in order to verify that the
endpoint can respond to requests. Super Node expects to connect with SSL, and will
send a JSON hash. 
- ` { "token": "a_token", "bucket_id": "AAf3lkeq34..", "created_at": "2012-02-13T00:39:34Z" } `

In return it expects and a status of 200 with the `token` mirrored
back. Any other response will delete the batch, andd further requests to said batch will be ignored.
- ` { "token": "given_token" } `

bbb=ActiveSupport::JSON.encode([{"relative_url"=>"760545392/feed", "method"=>"GET"}, {"relative_url"=>"762872003/feed", "method"=>"GET"}, {"relative_url"=>"802085146/feed", "method"=>"GET"}, {"relative_url"=>"824566520/feed", "method"=>"GET"}, {"relative_url"=>"836202/feed", "method"=>"GET"}, {"relative_url"=>"856020598/feed", "method"=>"GET"}, {"relative_url"=>"895470383/feed", "method"=>"GET"}])

g={"access_token"=>"AAACEdEose0cBAJ5zZBifGg90CjLU9BIoX19QVxwC41sBBZCbnFF93hvyRc3ZBtNymxfmx5bNQNeWACVfql5zxbvHMD5a7DbhoSz9zSaiwZDZD", "batch"=>bbb}

SuperNode::HTTP.new('https://graph.facebook.com').post(g)

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

