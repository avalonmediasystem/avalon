# Base stage for building gems
FROM        ruby:2.5-buster as bundle
LABEL       stage=build
LABEL       project=avalon
RUN     echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list && \
        apt-get update && apt-get upgrade -y build-essential \
         && apt-get install -y --no-install-recommends \
            cmake \
            pkg-config \
            zip \
            git \
            #libyaz-dev \
            gcc-7 \
            g++-7 \
            # gcc-8 \
            # g++-8 \
         && rm -rf /var/lib/apt/lists/* \
         && apt-get clean \
         && ls -l /usr/bin/g* \
         && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 20 \
         && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 20 \
         && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8 \
         && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8 \
         #&& update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9 \
         #&& update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9 \
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
RUN         bundle install --with aws development test postgres --without production


# Download binaries in parallel
FROM        ruby:2.5-buster as download
LABEL       stage=build
LABEL       project=avalon
RUN         curl -L https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz | tar xvz -C /usr/bin/
RUN         curl https://chromedriver.storage.googleapis.com/2.46/chromedriver_linux64.zip -o /usr/local/bin/chromedriver \
         && chmod +x /usr/local/bin/chromedriver
RUN         curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /chrome.deb
RUN         mkdir -p /tmp/ffmpeg && cd /tmp/ffmpeg \
         && curl https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | tar xJ \
         && cp `find . -type f -executable` /usr/bin/


# Base stage for building final images
FROM        ruby:2.5-slim-buster as base
LABEL       stage=build
LABEL       project=avalon
RUN         echo 'APT::Default-Release "stretch";' > /etc/apt/apt.conf.d/99defaultrelease \
         && echo "deb     http://ftp.us.debian.org/debian/    testing main contrib non-free"  >  /etc/apt/sources.list.d/testing.list \
         && echo "deb-src http://ftp.us.debian.org/debian/    testing main contrib non-free"  >> /etc/apt/sources.list.d/testing.list \
         && cat /etc/apt/apt.conf.d/99defaultrelease \
         && cat /etc/apt/sources.list.d/testing.list \
         && apt-get update && apt-get install -y --no-install-recommends curl gnupg2 \
         && curl -sL http://deb.nodesource.com/setup_12.x | bash - \
         && curl -O https://mediaarea.net/repo/deb/repo-mediaarea_1.0-16_all.deb && dpkg -i repo-mediaarea_1.0-16_all.deb \
         && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
         && echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
         && curl -sL http://deb.nodesource.com/setup_8.x | bash - \
         && cat /etc/apt/sources.list.d/nodesource.list

RUN         apt-get update && \
            # apt-get install --fix-broken && \
            apt-get -y dist-upgrade && \
            apt-get install -y --no-install-recommends --allow-unauthenticated \
            nodejs \
            yarn \
            #npm \
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
            #libyaz-dev \
         && apt-get -y -t testing install mediainfo \
         #&& npm install yarn \
         && ln -s /usr/bin/lsof /usr/sbin/


RUN         useradd -m -U app \
         && su -s /bin/bash -c "mkdir -p /home/app/avalon" app
WORKDIR     /home/app/avalon

COPY        --from=download /usr/bin/ff* /usr/bin/



# Build devevelopment image
FROM        base as dev
LABEL       stage=final
LABEL       project=avalon
RUN         apt-get install -y --no-install-recommends --allow-unauthenticated \
            build-essential \
            gcc-7 \
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
RUN         bundle install --without development test --with aws production postgres


# Install node modules
FROM        node:12-buster-slim as node-modules
LABEL       stage=build
LABEL       project=avalon
RUN         apt-get update && apt-get install -y --no-install-recommends git
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
