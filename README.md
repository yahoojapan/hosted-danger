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
> ACCESS_TOKEN=hoge make build

# rm & stop the container
> make stop

# run the server
> make run

# run the server and keep it interactive
> make run-i

# build -> stop -> run
> ACCESS_TOKEN=hoge make rerun

# build -> stop -> run-i
> ACCESS_TOKEN=hoge make rerun-i
```


hoge
