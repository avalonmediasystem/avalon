#!/bin/bash

yarn install

bundle install && \
cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml

rm -f tmp/pids/server.pid
bundle exec rake db:migrate

yarn build:test

#Ignore any errors with db:migrate and go ahead with startup
exit 0
