#!/bin/bash

cd /home/app/avalon
export HOME=/home/app

# Workaround from https://github.com/yarnpkg/yarn/issues/2782
yarn install

bundle install && \
cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml

BACKGROUND=yes QUEUE=* bundle exec rake resque:work
BACKGROUND=yes bundle exec rake environment resque:scheduler

rm -f tmp/pids/server.pid
bundle exec rake db:migrate

