# Base stage for building gems
FROM        ruby:2.7-bullseye as bundle
LABEL       stage=build
LABEL       project=avalon
RUN        apt-get update && apt-get upgrade -y build-essential && apt-get autoremove \
         && apt-get install -y --no-install-recommends --fix-missing \
            cmake \
            pkg-config \
            zip \
            git \
            ffmpeg \
            libsqlite3-dev \
         && rm -rf /var/lib/apt/lists/* \
         && apt-get clean \
         && ls -l /usr/bin/g* \
         && gcc --version \
         && g++ --version

COPY        Gemfile ./Gemfile
COPY        Gemfile.lock ./Gemfile.lock

RUN         gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)" \
         && bundle config build.nokogiri --use-system-libraries


# Build development gems
FROM        bundle as bundle-dev
LABEL       stage=build
LABEL       project=avalon
RUN         bundle config set --local without 'production' \
         && bundle config set --local with 'aws development test postgres' \
         && bundle install


# Download binaries in parallel
FROM        ruby:2.7-bullseye as download
LABEL       stage=build
LABEL       project=avalon
RUN         curl -L https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz | tar xvz -C /usr/bin/
RUN         curl https://chromedriver.storage.googleapis.com/2.46/chromedriver_linux64.zip -o /usr/local/bin/chromedriver \
         && chmod +x /usr/local/bin/chromedriver
RUN         curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /chrome.deb
RUN      apt-get -y update && apt-get install -y ffmpeg


# Base stage for building final images
FROM        ruby:2.7-slim-bullseye as base
LABEL       stage=build
LABEL       project=avalon
RUN         echo "deb     http://ftp.us.debian.org/debian/    bullseye main contrib non-free"  >  /etc/apt/sources.list.d/bullseye.list \
         && echo "deb-src http://ftp.us.debian.org/debian/    bullseye main contrib non-free"  >> /etc/apt/sources.list.d/bullseye.list \
         && cat /etc/apt/sources.list.d/bullseye.list \
         && apt-get update && apt-get install -y --no-install-recommends curl gnupg2 ffmpeg \
         && curl -sL http://deb.nodesource.com/setup_12.x | bash - \
         && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
         && echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
         && cat /etc/apt/sources.list.d/nodesource.list \
         && cat /etc/apt/sources.list.d/yarn.list

RUN         apt-get update && \
            apt-get -y dist-upgrade && \
            apt-get install -y --no-install-recommends --allow-unauthenticated \
            nodejs \
            yarn \
            lsof \
            x264 \
            sendmail \
            git \
            libxml2-dev \
            libxslt-dev \
            libpq-dev \
            openssh-client \
            zip \
            dumb-init \
            libsqlite3-dev \
         && apt-get -y install mediainfo \
         && ln -s /usr/bin/lsof /usr/sbin/

RUN         useradd -m -U app \
         && su -s /bin/bash -c "mkdir -p /home/app/avalon" app
WORKDIR     /home/app/avalon


# Build devevelopment image
FROM        base as dev
LABEL       stage=final
LABEL       project=avalon
RUN         apt-get install -y --no-install-recommends --allow-unauthenticated \
            build-essential \
            cmake

COPY        --from=bundle-dev /usr/local/bundle /usr/local/bundle
COPY        --from=download /chrome.deb /
COPY        --from=download /usr/local/bin/chromedriver /usr/local/bin/chromedriver
COPY        --from=download /usr/bin/dockerize /usr/bin/
ADD         docker_init.sh /

ARG         RAILS_ENV=development
RUN         dpkg -i /chrome.deb || apt-get install -yf


# Build production gems
FROM        bundle as bundle-prod
LABEL       stage=build
LABEL       project=avalon
RUN         bundle config set --local without 'development test' \
         && bundle config set --local with 'aws production postgres' \
         && bundle install


# Install node modules
FROM        node:12-bullseye-slim as node-modules
LABEL       stage=build
LABEL       project=avalon
RUN         apt-get update && apt-get install -y --no-install-recommends git ca-certificates
COPY        package.json .
COPY        yarn.lock .
RUN         yarn install


# Build production assets
FROM        base as assets
LABEL       stage=build
LABEL       project=avalon
COPY        --from=bundle-prod --chown=app:app /usr/local/bundle /usr/local/bundle
COPY        --chown=app:app . .
COPY        --from=node-modules --chown=app:app /node_modules ./node_modules

USER        app
ENV         RAILS_ENV=production

RUN         SECRET_KEY_BASE=$(ruby -r 'securerandom' -e 'puts SecureRandom.hex(64)') bundle exec rake webpacker:compile
RUN         SECRET_KEY_BASE=$(ruby -r 'securerandom' -e 'puts SecureRandom.hex(64)') bundle exec rake assets:precompile
RUN         cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml


# Build production image
FROM        base as prod
LABEL       stage=final
LABEL       project=avalon
COPY        --from=assets --chown=app:app /home/app/avalon /home/app/avalon
COPY        --from=bundle-prod --chown=app:app /usr/local/bundle /usr/local/bundle

USER        app
ENV         RAILS_ENV=production
