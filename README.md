# Hosted Danger

## Building
```bash
shards build
```

## Testing
```bash
crystal spec
```

## Run with docker (recommended)

### Requirements
- docker
- [docker-clean](https://github.com/ZZROTDesign/docker-clean)

### Commands
```bash
# build
> ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make build

# rm & stop the container
> make stop

# run the server as daemon
> make run

# run the server and keep it interactive
> make run-i

# build -> stop -> run
> ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make rerun

# build -> stop -> run-i
> ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make rerun-i
```

*) Env vars related to dragon is used for [BundlerCache](https://ghe.corp.yahoo.co.jp/approduce/BundlerCache).
