[![Cult Of Martians](http://cultofmartians.com/assets/badges/badge.svg)](https://cultofmartians.com/tasks/anycable-ruby-server.html)
[![Gem Version](https://badge.fury.io/rb/anycable-rack-server.svg)](https://rubygems.org/gems/anycable-rack-server)
[![Build](https://github.com/anycable/anycable-rack-server/workflows/Build/badge.svg)](https://github.com/anycable/nycable-rack-server/actions)

# anycable-rack-server

[AnyCable](https://anycable.io)-compatible Rack hijack based Ruby Web Socket server designed for development and testing purposes.

## Using with Rack

```ruby
# Initialize server instance first.
#
# NOTE: you must run RPC server yourself and provide its host
ws_server = AnyCable::Rack::Server.new rpc_host: "localhost:50051"

app = Rack::Builder.new do
  map "/cable" do
    run ws_server
  end
end

# NOTE: don't forget to call `start!` method
ws_server.start!

run app
```

## Usage with Rails

Add `gem "anycable-rack-server"` to you `Gemfile` and make sure your Action Cable adapter is set to `:any_cable`. That's it! We automatically start AnyCable Rack server for your at `/cable` path.

## Settings

You can customize the headers being sent with each gRPC request.

Default headers: `'cookie', 'x-api-token'`.

Can be specified via options:

```ruby
ws_server = AnyCable::Rack::Server.new(
  rpc_host: "localhost:50051",
  headers: ["cookie", "x-my-header"]
)
```

In case of Rails you can set server options via `config.any_cable_rack`:

```ruby
# <environment>.rb
config.any_cable_rack.headers = %w[cookie]
config.any_cable_rack.mount_path = "/cable"
# NOTE: here we specify only the port (we assume that a server is running locally)
config.any_cable_rack.rpc_port = 50051
```

## Running RPC from the same process

The goal of the Rack server is to simplify the development/testing process. But we still have to run the RPC server.

This gem also provides a way to run RPC server from the same process (spawning a new process):

```ruby
# in Rack app

AnyCable::Rack::RPCRunner.run(
  root_dir: "<path to your app root directory to run `anycable` from>",
  rpc_host: "...", # optional host to run RPC server on (defaults to '[::]::50051')
  command_args: [] # additional CLI arguments
)

# in Rails app you can just specify the configuration parameter (`false` by default)
# and we'll take care of it
config.any_cable_rack.run_rpc = true
```

## Using HTTP broadcast adapter

### With Rack

```ruby
ws_server = AnyCable::Rack::Server.new(
  rpc_host: "localhost:50051",
  broadcast_adapter: :http
)

app = Rack::Builder.new do
  map "/cable" do
    run ws_server
  end

  map "/_anycable_rack_broadcast" do
    run ws_server.broadcast
  end
end
```

### With Rails

Add the following configuration:

```ruby
config.any_cable_rack.broadcast_adapter = :http
# (optionally) Specify the mounting path
config.any_cable_rack.http_broadcast_path = "/_anycable_rack_server" # this is the default value
```

### Adding authorization check

You can restrict an access to the broadcast endpoint by specifying the `http_broadcast_secret` configuration parameter.

## Testing

Run units with `bundle exec rake`.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/anycable/anycable-rack-server](https://github.com/anycable/anycable-rack-server).

## License

The gem is available as open source under the terms of the [MIT License](./LICENSE).
