# Hosted Danger

## Build on local

### Requirements
- crystal

### Commands
```bash
shards build
```

## Run with docker

### Requirements
- docker
- https://github.com/ZZROTDesign/docker-clean

### Commands
```bash
# build
> ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make build

# rm & stop the container
> make stop

# run the server
> make run

# run the server and keep it interactive
> make run-i

# build -> stop -> run
> ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make rerun

# build -> stop -> run-i
> ACCESS_TOKEN=hoge DRAGON_ACCESS_KEY=fuga DRAGON_SECRET_ACCESS_KEY=hoga make rerun-i
```

* Dragon関係の環境変数は[BundlerCache](https://ghe.corp.yahoo.co.jp/approduce/BundlerCache)に利用します
