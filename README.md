[![Cult Of Martians](http://cultofmartians.com/assets/badges/badge.svg)](https://cultofmartians.com/tasks/anycable-ruby-server.html)
[![Gem Version](https://badge.fury.io/rb/anycable-rack-server.svg)](https://rubygems.org/gems/anycable-rack-server)
[![Build](https://github.com/anycable/anycable-rack-server/workflows/Build/badge.svg)](https://github.com/anycable/anycable-rack-server/actions)

# anycable-rack-server

[AnyCable](https://anycable.io)-compatible Rack hijack based Ruby Web Socket server designed for development and testing purposes.

## Using with Rack

```ruby
# Initialize server instance first.
ws_server = AnyCable::Rack::Server.new

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

## Configuration

AnyCable Rack Server uses [`anyway_config`](https://github.com/palkan/anyway_config) gem for configuration; thus it is possible to set configuration parameters through environment vars (prefixed with `ANYCABLE_`), `config/anycable.yml` file or `secrets.yml` when using Rails.

**NOTE:** AnyCable Rack Server uses the same config name (i.e., env prefix, YML file name, etc.) as AnyCable itself.

You can pass a config object as the option to `AnyCable::Rack::Server.new`:

```ruby
server = AnyCable::Server::Rack.new(config: AnyCable::Rack::Config.new(**params))
```

If no config is passed, a default, global, configuration would be used (`AnyCable::Rack.config`).

When using Rails, `config.anycable_rack` points to `AnyCable::Rack.config`.

### Headers

You can customize the headers being sent with each gRPC request.

Default headers: `'cookie', 'x-api-token'`.

Can be specified via configuration:

```ruby
AnyCable::Rack.config.headers = ["cookie", "x-my-header"]
```

Or in Rails:

```ruby
# <environment>.rb
config.any_cable_rack.headers = %w[cookie]
```

### Rails-specific options

```ruby
# Mount WebSocket server at the specified path
config.any_cable_rack.mount_path = "/cable"
# NOTE: here we specify only the port (we assume that a server is running locally)
config.any_cable_rack.rpc_port = 50051
```

## Broadcast adapters

AnyCable Rack supports Redis (default) and HTTP broadcast adapters
(see [the documentation](https://docs.anycable.io/ruby/broadcast_adapters)).

Broadcast adapter is inherited from AnyCable configuration (so, you don't need to configure it twice).

### Using HTTP broadcast adapter

### With Rack

```ruby
AnyCable::Rack.config.broadast_adapter = :http

ws_server = AnyCable::Rack::Server

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

By default, we mount broadcasts endpoint at `/_anycable_rack_broadcast`.

You can change this setting:

```ruby
config.any_cable_rack.http_broadcast_path = "/_my_broadcast"
```

**NOTE:** Don't forget to configure `http_broadcast_url` for AnyCable pointing to your web server and the specified broadcast path.

## Testing

Run units with `bundle exec rake`.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/anycable/anycable-rack-server](https://github.com/anycable/anycable-rack-server).

## License

The gem is available as open source under the terms of the [MIT License](./LICENSE).
