#!/bin/bash

cd /home/app/avalon
export HOME=/home/app

# Workaround from https://github.com/yarnpkg/yarn/issues/2782
yarn install

bundle install && \
cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml

rm -f tmp/pids/server.pid
bundle exec rake db:migrate

