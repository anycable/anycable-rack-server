# anycable-rack-server

AnyCable-compatible Rack hijack based Ruby Web Socket server middleware designed for development and testing purposes.

## Usage

Specify the RPC host env variable
```
ANYCABLE_RPC_HOST=rpc:50051
```

Set up the server in the initializers or within the app server script
```ruby
AnyCable::RackServer.setup!
```

Mount the rack middleware
```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount AnyCable::Rack => '/cable'
end
```