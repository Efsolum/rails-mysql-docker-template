#!/usr/bin/env bash
set -e

[ -f './project.bash' ] && source './project.bash'

PROJECT_NAME=${PROJECT_NAME:-'project'}

RAILS_VERSION=${RAILS_VERSION:='4.2.6'}
RUBY_VERSION=${RUBY_VERSION:-'2.3.1'}
NODE_VERSION=${NODE_VERSION:-'6.2.0'}

MYSQL_VERSION=${MYSQL_VERSION:-'10.1.14'}

DATABASE_USER=${DATABASE_USER:-'app'}
DATABASE_PASS=${DATABASE_PASS:-'password'}

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
			 --env="DATABASE_USER=${DATABASE_USER}" \
			 --env="DATABASE_PASS=${DATABASE_PASS}" \
			 "${PROJECT_NAME}/mysql-dbms:latest"

docker run \
			 --detach=true \
			 --name='rails-web' \
			 --publish='3000:3000' \
			 --volume="$(dirname $(pwd))/src:/var/www/projects" \
			 "${PROJECT_NAME}/rails-${RUBY_VERSION}-${RAILS_VERSION}:latest"

docker run \
			 --detach=true \
			 --name='node-assets' \
			 --volume="$(dirname $(pwd))/src:/var/www/projects" \
			 "${PROJECT_NAME}/node-${NODE_VERSION}:latest"
