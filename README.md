# anycable-rack-server

AnyCable-compatible Rack hijack based Ruby Web Socket server middleware designed for development and testing purposes.

## Usage

Mount the rack middleware
```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount AnyCable::Rack.new => '/cable'
end
```

## Settings

Customizable options: gRPC server host and headers being sent with each gRPC request.
The gem uses redis settings specified in AnyCable config.

Can be specified via env variables
```
ANYCABLE_RPC_HOST=rpc:50051
ANYCABLE_HEADERS=cookie,x-api-token,origin
```

Or

```ruby
options = { rpc_host: 'localhost:50052', headers: ['cookie', 'origin'] }
AnyCable::Rack.new(nil, options)
```

## Testing

Run units with `rake`.

Instructions for testing with [anyt](https://github.com/anycable/anyt) (anycable conformance testing) can be found [here](https://github.com/tuwukee/anycable-rack-server/tree/master/test/support).
