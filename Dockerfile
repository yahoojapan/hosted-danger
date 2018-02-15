FROM crystallang/crystal

# base
RUN apt-get update -y
RUN apt-get install curl wget dnsutils locales locales-all -y

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8

# crystal
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
COPY Dangerfile.default /tmp/hd/Dangerfile.default

RUN cd /tmp/hd && shards build

EXPOSE 80

ADD token.json /tmp/hd/token.json
CMD /tmp/hd/bin/hosted-danger
