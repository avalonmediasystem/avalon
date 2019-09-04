# Base stage for building gems
FROM        ruby:2.5.5-stretch as base
ENV         BUNDLER_VERSION 2.0.2
RUN         echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
         && apt-get update && apt-get upgrade -y build-essential \
         && apt-get install -y --no-install-recommends \
            cmake \
            pkg-config \
            zip \
            git \
         && gem install bundler \
         && rm -rf /var/lib/apt/lists/* \
         && apt-get clean

RUN         mkdir -p /home/app/avalon
WORKDIR     /home/app/avalon

COPY        Gemfile ./Gemfile
COPY        Gemfile.lock ./Gemfile.lock
RUN         bundle config build.nokogiri --use-system-libraries \
         && bundle install --with aws development test postgres --without production 


# Download stage takes advantage of parallel build
FROM        ruby:2.5.5-stretch as download
RUN         curl https://chromedriver.storage.googleapis.com/2.46/chromedriver_linux64.zip -o /usr/local/bin/chromedriver \
         && chmod +x /usr/local/bin/chromedriver \
         && curl -L https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz | tar xvz -C /usr/bin/ \
         && mkdir -p /tmp/ffmpeg && cd /tmp/ffmpeg \
         && curl https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | tar xJ \
         && cp `find . -type f -executable` /usr/bin/


# Dev stage for building dev image
FROM        ruby:2.5.5-slim-stretch as dev
ENV         BUNDLER_VERSION 2.0.2
RUN         apt-get update && apt-get install -y --no-install-recommends curl gnupg2 \
         && curl -sL http://deb.nodesource.com/setup_8.x | bash - \
         && curl -O https://mediaarea.net/repo/deb/repo-mediaarea_1.0-6_all.deb && dpkg -i repo-mediaarea_1.0-6_all.deb \
         && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
         && echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN         apt-get update && apt-get install -y --no-install-recommends \
            yarn \
            nodejs \
            lsof \
            x264 \
            sendmail \
            git \
            libxml2-dev \
            libxslt-dev \
            libpq-dev \
            mediainfo \
            openssh-client \
            zip \
         && gem install bundler \
         && curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /chrome.deb \
         && dpkg -i /chrome.deb || apt-get install -yf \
         && ln -s /usr/bin/lsof /usr/sbin/

ARG         AVALON_BRANCH=develop
ARG         RAILS_ENV=development
ARG         BASE_URL
ARG         DATABASE_URL
ARG         SECRET_KEY_BASE

COPY        --from=base /usr/local/bundle /usr/local/bundle
COPY        --from=download /usr/local/bin/chromedriver /usr/local/bin/chromedriver
COPY        --from=download /usr/bin/ff* /usr/bin/
COPY        --from=download /usr/bin/dockerize /usr/bin/

WORKDIR     /home/app/avalon
ADD         docker_init.sh /
