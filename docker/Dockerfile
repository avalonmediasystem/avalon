FROM        ruby:2.5.5-stretch
MAINTAINER  Phuong Dinh <pdinh@indiana.edu>

RUN         curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
         && echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
         && curl -sL http://deb.nodesource.com/setup_8.x | bash - \
         && echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
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
            zip \
         && gem install bundler \
         && curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /chrome.deb \
         && dpkg -i /chrome.deb || apt-get install -yf && rm /chrome.deb \
         && curl https://chromedriver.storage.googleapis.com/2.46/chromedriver_linux64.zip -o /usr/local/bin/chromedriver \
         && chmod +x /usr/local/bin/chromedriver \
         && curl -L https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz | tar xvz -C /usr/bin/ \
         && rm -rf /var/lib/apt/lists/* \
         && apt-get clean

RUN         mkdir -p /tmp/ffmpeg && cd /tmp/ffmpeg \
         && curl https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | tar xJ \
         && cp `find . -type f -executable` /usr/bin/ \
         && ln -s /usr/bin/lsof /usr/sbin/

RUN         mkdir -p /home/app/avalon

WORKDIR     /home/app/avalon
ARG         AVALON_BRANCH=develop
ARG         RAILS_ENV=development
ARG         BASE_URL
ARG         DATABASE_URL
ARG         SECRET_KEY_BASE
ADD         rails_init-*.sh /
