FROM crystallang/crystal

# crystal
RUN apt-get update -y
RUN crystal --version
RUN shards --version

# anyenv
RUN apt-get install ruby -y
RUN ruby --version
RUN gem install bundler danger --no-ri --no-rdoc

# hd
RUN mkdir -p /tmp/hd

COPY src /tmp/hd/src
COPY shard.yml shard.lock /tmp/hd/

RUN cd /tmp/hd && shards build

EXPOSE 80

ADD token /tmp/hd/token
CMD /tmp/hd/bin/hosted-danger
