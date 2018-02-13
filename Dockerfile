FROM crystallang/crystal

# crystal
RUN apt-get update -y
RUN crystal --version
RUN shards --version

# ruby
RUN apt-get install ruby -y
RUN ruby --version
RUN gem install bundler --no-ri --no-rdoc

# gems
RUN mkdir /tmp/gem
COPY Gemfile /tmp/gem
RUN cd /tmp/gem && /bin/bash -l -c "bundle install --system"

# hd
RUN mkdir -p /tmp/hd

COPY src /tmp/hd/src
COPY shard.yml shard.lock /tmp/hd/
COPY Dangerfile /tmp/hd/Dangerfile.default

RUN cd /tmp/hd && shards build

EXPOSE 80

ADD token.json /tmp/hd/token.json
CMD /tmp/hd/bin/hosted-danger
