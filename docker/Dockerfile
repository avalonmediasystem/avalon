FROM        ruby:2.4.4-jessie
MAINTAINER  Phuong Dinh <pdinh@indiana.edu>

RUN         curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
         && echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
         && curl -sL http://deb.nodesource.com/setup_8.x | bash - \
         && echo "deb http://ftp.uk.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
         && wget https://mediaarea.net/repo/deb/repo-mediaarea_1.0-6_all.deb && dpkg -i repo-mediaarea_1.0-6_all.deb 

RUN         apt-get update && apt-get upgrade -y build-essential nodejs \
         && apt-get install -y \
            mediainfo \
            x264 \
            cmake \
            pkg-config \
            lsof \
            sendmail \
            yarn \
         && rm -rf /var/lib/apt/lists/* \
         && apt-get clean

RUN         mkdir -p /tmp/phantomjs \
         && curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar -xj --strip-components=1 -C /tmp/phantomjs \
         && mv /tmp/phantomjs/bin/phantomjs /usr/local/bin \
         && mkdir -p /tmp/ffmpeg && cd /tmp/ffmpeg \
         && curl https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-64bit-static.tar.xz | tar xJ \
         && cp `find . -type f -executable` /usr/bin/ \
         && ln -s /usr/bin/lsof /usr/sbin/

RUN         mkdir -p /home/app/avalon

WORKDIR     /home/app/avalon
ARG         AVALON_BRANCH=develop
ARG         RAILS_ENV=development
ARG         BASE_URL
ARG         DATABASE_URL
ARG         SECRET_KEY_BASE
ADD         rails_init-dev.sh /
