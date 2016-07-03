#!/usr/bin/env bash
set -e

RAILS_VERSION='4.2.6'
RUBY_VERSION='2.3.1'
RUBY_SHA256='b87c738cb2032bf4920fef8e3864dc5cf8eae9d89d8d523ce0236945c5797dcd'
ALPINE_VERSION='3.4'

CONTAINER_USER=developer
TEMP_DIR=$(mktemp --directory rails-build-XXXXXXXX)

docker_end() {
		exit=$?

		echo 'Cleaning up'
		rm -r $TEMP_DIR

		exit $exit;
}

trap docker_end EXIT SIGINT SIGTERM

cat <<EOF > $TEMP_DIR/Dockerfile
FROM alpine:${ALPINE_VERSION}
MAINTAINER 'Matthew Jordan <matthewjordandevops@yandex.com>'

ENV LANG en_US.UTF-8
ENV GEM_HOME /var/bundle
ENV BUNDLE_PATH /var/bundle
ENV BUNDLE_BIN /var/bundle/bin
ENV BUNDLE_SILENCE_ROOT_WARNING 1
ENV BUNDLE_APP_CONFIG /var/bundle
ENV PATH \$BUNDLE_BIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN adduser -u $(id -u $USER) -Ds /bin/bash $CONTAINER_USER
RUN apk update
RUN apk add \
				bash \
				build-base \
				curl-dev \
				git \
				libc-dev \
				libxml2 \
				libxml2-dev \
				libxslt \
				libxslt-dev \
				linux-headers \
				mysql-client \
				mysql-dev \
				nodejs \
				openssl \
				openssl-dev \
				sqlite-dev \
				sudo \
				tzdata \
				yaml \
				yaml-dev \
				zlib-dev \
			&& echo 'End of package list' \
			&& rm -rf '/var/cache/apk/*'

COPY ruby-build.bash /usr/local/bin/ruby-build.bash
RUN chmod u+x /usr/local/bin/ruby-build.bash
RUN ruby-build.bash

COPY Gemfile /tmp/Gemfile
WORKDIR /tmp
RUN gem install bundler
RUN bundle install

RUN mkdir /tmp/profile
WORKDIR /tmp/profile
COPY profile /tmp/profile/bash-profile
RUN cat bash-profile >> /etc/profile

WORKDIR /
RUN chown -R $CONTAINER_USER:$CONTAINER_USER \$BUNDLE_PATH
RUN chmod -R ug+rw \$BUNDLE_PATH

USER $CONTAINER_USER
WORKDIR /var/www/projects

EXPOSE 3000/tcp
VOLUME /var/www/projects
CMD sh -c 'kill -STOP \$$'
EOF

cat <<EOF > $TEMP_DIR/ruby-build.bash
#!/usr/bin/env bash
set -eo pipefail

mkdir -v /tmp/ruby-build
cd /tmp/ruby-build

wget 'https://cache.ruby-lang.org/pub/ruby/ruby-${RUBY_VERSION}.tar.gz'
sha256sum ruby-${RUBY_VERSION}.tar.gz | \
					grep $RUBY_SHA256

tar -xzf ruby-${RUBY_VERSION}.tar.gz

mkdir /tmp/ruby-build/ruby-${RUBY_VERSION}/build

cd /tmp/ruby-build/ruby-${RUBY_VERSION}/build
../configure --disable-install-rdoc
make
make install

rm -r /tmp/ruby-build
EOF

cat <<EOF >> $TEMP_DIR/profile

# Application variables
export GEM_HOME=/var/bundle
export BUNDLE_PATH=/var/bundle
export BUNDLE_BIN=/var/bundle/bin
export BUNDLE_SILENCE_ROOT_WARNING=1
export BUNDLE_APP_CONFIG=/var/bundle

export PATH="\$BUNDLE_BIN:\$PATH"
EOF

cat <<EOF > $TEMP_DIR/Gemfile
source 'https://rubygems.org'

gem 'rails', '~>${RAILS_VERSION}'
EOF

docker build -t "project/rails-${RUBY_VERSION}-${RAILS_VERSION}" $TEMP_DIR
docker tag \
			 "project/rails-${RUBY_VERSION}-${RAILS_VERSION}:latest" \
			 "project/mysql-dbms:$(date +%s)"
