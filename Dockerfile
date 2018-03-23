FROM crystallang/crystal:0.24.2

# base
RUN apt-get clean -y && apt-get update -y
RUN apt-get install curl libcurl3 libcurl3-gnutls libcurl4-openssl-dev wget dnsutils locales locales-all -y

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8

# crystal
RUN crystal --version
RUN shards --version

# ruby
RUN apt-get install ruby ruby-dev -y
RUN ruby --version
RUN gem install bundler --no-ri --no-rdoc
RUN gem install specific_install --no-ri --no-rdoc

# gems
RUN mkdir /tmp/gem
COPY Gemfile /tmp/gem
COPY Gemfile.lock /tmp/gem
RUN gem specific_install -l 'https://github.com/tbrand/danger.git'
RUN cd /tmp/gem && /bin/bash -l -c "bundle install --system"
RUN mv /usr/local/bin/danger /usr/local/bin/danger_ruby
RUN ls -la /usr/local/bin

# js
RUN apt-get install -y nodejs npm
RUN npm cache clean && npm install n -g
RUN n --latest && n --stable
RUN n stable
RUN apt-get purge -y nodejs npm
RUN npm install -g yarn
RUN node -v && npm -v && yarn -v
RUN yarn global add danger
RUN ln -s /usr/local/bin/danger /usr/local/bin/danger_js

RUN ls -la /usr/local/bin
RUN danger_ruby --version
RUN danger_js --version

# hd
RUN mkdir -p /tmp/hd

ADD envs.json /tmp/hd/envs.json
COPY shard.yml shard.lock /tmp/hd/

EXPOSE 80

COPY Dangerfile.default /tmp/hd/Dangerfile.default
COPY src /tmp/hd/src

RUN cd /tmp/hd && shards build

CMD /tmp/hd/bin/hosted-danger
