#!/usr/bin/env bash
set -e

NODE_VERSION='6.2.2'
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
ENV NPM_CONFIG_PREFIX /var/npm
ENV PATH \$NPM_CONFIG_PREFIX/bin:\$PATH

RUN adduser -u $(id -u $USER) -Ds /bin/bash $CONTAINER_USER

RUN apk update
RUN apk add \
					bash \
					curl \
					nodejs>=${NODE_VERSION} \
					nodejs-dev>=${NODE_VERSION} \
					openssl \
					sudo \
					tar \
				&& echo 'End of package list' \
				rm -rf '/var/cache/apk/*'

RUN mkdir \$NPM_CONFIG_PREFIX
RUN bash -c 'npm install -g \
							 		browserify \
							 		gulp \
							 && npm cache clean'

RUN mkdir /tmp/node-build
WORKDIR /tmp/node-build
COPY profile /tmp/node-build/bash-profile
RUN cat bash-profile >> /etc/profile

RUN chown -R root:$CONTAINER_USER \$NPM_CONFIG_PREFIX

USER $CONTAINER_USER
WORKDIR /var/www/projects

VOLUME ["/var/www/projects"]
CMD sh -c 'kill -STOP \$$'
EOF

cat <<EOF >> $TEMP_DIR/profile

# Application variables
export NPM_CONFIG_PREFIX=/var/npm
export PATH=\$NPM_CONFIG_PREFIX/bin:\$PATH
EOF

docker build -t "project/node-${NODE_VERSION}:latest" $TEMP_DIR
docker tag \
			 "project/node-${NODE_VERSION}:latest" \
			 "project/node-${NODE_VERSION}:$(date +%s)"
