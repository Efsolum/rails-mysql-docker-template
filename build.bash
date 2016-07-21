#!/usr/bin/env bash
set -e

PROJECT_NAME='project'

ALPINE_VERSION='3.4'

NODE_VERSION='6.2.0'

RAILS_VERSION='4.2.6'
RUBY_VERSION='2.3.1'
RUBY_SHA256='b87c738cb2032bf4920fef8e3864dc5cf8eae9d89d8d523ce0236945c5797dcd'

MYSQL_VERSION='10.1.14'

echo "==========> Building MySQL Image"
./mysql-build.bash

echo "==========> Building Java Image"
./rails-build.bash

echo "==========> Building NodeJS Image"
./nodejs-build.bash
