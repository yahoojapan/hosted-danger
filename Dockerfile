FROM crystallang/crystal:0.26.1

# base
RUN apt-get clean -y && apt-get update -y
RUN apt-get install curl libcurl3 libreadline-dev \
            libcurl3-gnutls libcurl4-openssl-dev wget zip unzip \
            dnsutils locales locales-all nodejs npm -y

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8

# ruby
ENV RUBY_VERSION 2.6.0
ENV RBENV_ROOT /root/.rbenv
RUN git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT && \
  git clone https://github.com/sstephenson/ruby-build.git $RBENV_ROOT/plugins/ruby-build
RUN $RBENV_ROOT/plugins/ruby-build/install.sh
ENV PATH $RBENV_ROOT/bin:$RBENV_ROOT/shims:$RBENV_ROOT/versions/$RUBY_VERSION/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
ENV CONFIGURE_OPTS --disable-install-doc
RUN rbenv install $RUBY_VERSION && rbenv global $RUBY_VERSION
RUN rbenv exec gem install bundler
RUN rbenv exec gem update --system

WORKDIR /opt/hd

COPY Gemfile Gemfile.lock ./

# gems
RUN gem install rake
RUN bundle install --system
RUN mv $RBENV_ROOT/versions/$RUBY_VERSION/bin/danger \
  $RBENV_ROOT/versions/$RUBY_VERSION/bin/danger_ruby

# js
RUN npm cache clean && npm install n -g
RUN n stable
RUN apt-get purge -y nodejs npm
RUN npm install -g yarn
RUN yarn global add danger
RUN ln -s /usr/local/bin/danger /usr/local/bin/danger_js

EXPOSE 80

COPY Dangerfile.default shard.yml shard.lock ./
COPY src ./src

RUN shards build --release
ENV PATH $PATH:/opt/hd/bin

CMD hosted-danger
