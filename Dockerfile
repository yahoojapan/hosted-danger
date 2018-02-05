FROM crystallang/crystal

# crystal
RUN apt-get update -y
RUN crystal --version
RUN shards --version

# anyenv
RUN apt-get install ruby -y
RUN ruby --version
RUN gem install danger --no-ri --no-rdoc

# app
RUN mkdir -p /tmp/app

COPY src /tmp/app/src
COPY shard.yml shard.lock /tmp/app/

RUN cd /tmp/app && shards build

EXPOSE 80

CMD /tmp/app/bin/hosted-danger
