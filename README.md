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
make build   # build
make run     # run the server
make run-i   # run the server and keep it interactive
make stop    # rm & stop the container
make rerun   # build -> stop -> run
make rerun-i # build -> stop -> run-i
```

hoge
