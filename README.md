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

Customizable options: headers being sent with each gRPC request. The gem uses AnyCable config for redis and gRPC host settings.

Default headers: `'cookie', 'x-api-token'`.

Can be specified via env variable
```
ANYCABLE_HEADERS=cookie,x-api-token,origin
```

Or

```ruby
options = { headers: ['cookie', 'origin'] }
AnyCable::Rack.new(nil, options)
```

## Testing

Run units with `rake`.

Instructions for testing with [anyt](https://github.com/anycable/anyt) (anycable conformance testing) can be found [here](https://github.com/tuwukee/anycable-rack-server/tree/master/test/support).
