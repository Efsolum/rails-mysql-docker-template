#!/usr/bin/env bash
set -e

RAILS_VERSION='4.2.6'
RUBY_VERSION='2.3.1'
NODE_VERSION='6.2.2'

docker_err() {
		exit=$?

		echo '/nStoping containers'
		docker stop mysql-dbms rails-web node-assets

		exit $exit;
}

trap docker_err ERR

docker run \
			 --detach=true \
			 --name='mysql-dbms' \
			 --env='user=app' \
			 --env='password=password' \
			 'project/mysql-dbms:latest'

docker run \
			 --detach=true \
			 --name='rails-web' \
			 --volume="$(dirname $(pwd))/src:/var/www/projects" \
			 "project/rails-${RUBY_VERSION}-${RAILS_VERSION}:latest"

docker run \
			 --detach=true \
			 --name='node-assets' \
			 --volume="$(dirname $(pwd))/src:/var/www/projects" \
			 "project/node-${NODE_VERSION}:latest"
