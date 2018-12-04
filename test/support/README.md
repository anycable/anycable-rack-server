# README

Test anycable-rack-server with anyt.

On default it uses an internal broadcast adapter, broadcasting via redis through external process will fail.

```
anyt --debug -c "rackup config.ru -E production" --only request/connection
```
