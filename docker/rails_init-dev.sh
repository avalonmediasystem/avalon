#!/bin/bash

cd /home/app/avalon
export HOME=/home/app

# Workaround from https://github.com/yarnpkg/yarn/issues/2782
yarn config set -- --modules-folder "/home/app/node_modules"
yarn install

bundle config build.nokogiri --use-system-libraries && \
bundle install --path=/home/app/gems --with postgres && \
bundle exec whenever -w -f config/docker_schedule.rb && \
bundle exec rake assets:precompile && \
cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml

BACKGROUND=yes QUEUE=* bundle exec rake resque:work
BACKGROUND=yes bundle exec rake environment resque:scheduler

rm -f tmp/pids/server.pid
bundle exec rake db:migrate
bundle exec rails server -b 0.0.0.0 -p 80 
tail -f /dev/null

