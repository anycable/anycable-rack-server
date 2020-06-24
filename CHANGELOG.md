# Change log

## master

- Embed RPC server into the running process instead of spawning a new one. ([@palkan][])

Use `AnyCable::CLI.new(embedded: true)` when `config.run_rpc = true` instead of spawning a new process.

- Added HTTP broadcast support. ([@palkan])

Broadcast adapter is inherited from AnyCable (i.e, no need to specify it twice).

- **Breaking** Server initialization and configuration API changes. ([@palkan][])

Now you need to pass a config object as the only option to `AnyCable::Rack::Server.new`:

```ruby
server = AnyCable::Server::Rack.new(config: AnyCable::Rack::Config.new(**params))
```

You can omit the config altogether. In this case, a default, global, configuration would be used (`AnyCable::Rack.config`).

When using Rails, `config.anycable_rack` points to `AnyCable::Rack.config`.

Env variables prefix for configuration changed from `ANYCABLE_RACK_` to `ANYCABLE_`
That would allow us to re-use common parameters between `anycable` and `anycable-rack-server`.

- Make compatible with AnyCable v1.0. ([@palkan][])

## 0.1.0 (2019-01-06)

- Initial implementation. ([@tuwukee][])

[@palkan]: https://github.com/palkan
[@tuwukee]: https://github.com/tuwukee
