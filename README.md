#Super Node

##An Asynchronous background queue that is accessable via a simple API.

###The easiest way to request data from Super Node is to `POST` to `/enqueue`.

#####Request endpoints
- `POST` to `/enqueue`
- `POST` to `/batch`
- `PUT` to `/batch/:batch_id`
- `DELETE` to `/batch/:batch_id`

#/enqueue

####use to add a request to a batch

#####Required paramteters:
- `token` - This random string that will serve to verify the authenticity of the request. This field is mirrored upon response.
- `invocation` - A hash of the stringified invocation.

#####Optional parameters:
- `data` - A hash of identifying data. This field is mirrored upon response.
- `batch_id` - A unique identifier for bucket that requests will be processed from. Defaults to the 'primary' batch

#####Sample request:
######Performs the Invocation as `Fetcher.perform("/me", { "access_token": "g903jDJa", ... })`
```javascript
  {
    "token": "AAf3lkeq34...",
     "data": { "account_id": 7, ... },
     "invocation": {
       "class": "Fetcher",
       "method": "perform",
       "params": ["/me", { "access_token": "g903jDJa", ... }]
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
    "batch_id": "JS2s0yw93dj",
    "metadata": { "account_id": 7, "type": "FacebookPost", ... },
    "data": [
      { ..(B).. },
    ]
  }
```

#####(A). Sample error:
```javascript
  {
    "code": 401,
    "batch_id": "JS2s0yw93dj",
    "metadata": { "account_id": 7, ... },
    "data": []
  }
```

#####(B). Sample 'data item':
Each item from the list of data items in (A) is of type (B).

```javascript
  {
    "code": 200,
    "token": "AAf3lkeq34..."
    "metadata": { },
    "response": { }
  }
```

##/batch

####use to create a new batch (bucket)

#####Required parameters:
- `callback_url` - The url that will be `POST`ed to upon response.
- `batch_id` - The unique identifier for this bucket.

#####Optional parameters:
- `batch_timeout` - Number of miliseconds between commits
- `metadata` - Some extra information about the batch. Mirrored

#####Sample batch creation
that the server is ready to accept connections.
```javascript
  {
    "callback_url": "https://10.10.203.4/messages/callback.json",
    "batch_id": "AAf3lkeq34...",
    metadata: { ... },
    "batch_timeout": 60000
  }
```

#####Upon creating the batch:
Super Node will `POST` to the callback_url to in order to verify that the
endpoint can respond to requests. Super Node expects to connect with SSL, and will
send a JSON hash. 
- ` { "token": "a_token", "batch_id": "AAf3lkeq34...", "created_at": "2012-02-13T00:39:34Z" } `

In return it expects and a status of 200 with the `token` mirrored
back. Any other response will delete the batch, andd further requests to said batch will be ignored.
- ` { "token": "given_token" } `

