#!/bin/bash

cd /home/app/avalon
export HOME=/home/app

# Workaround from https://github.com/yarnpkg/yarn/issues/2782
yarn config set -- --modules-folder "/home/app/node_modules"
yarn install

bundle config build.nokogiri --use-system-libraries && \
bundle install --path=/home/app/gems --with aws development test postgres --without production --jobs=4 --retry=3 && \
cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml

rm -f tmp/pids/server.pid
bundle exec rake db:migrate
tail -f /dev/null
