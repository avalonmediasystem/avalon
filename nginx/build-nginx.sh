#!/bin/sh
cd /usr/src && apt-get source nginx && mv nginx-* nginx
cd /usr/src && git clone https://github.com/kaltura/nginx-vod-module.git && cd nginx-vod-module && git checkout -b latest-tag $(git describe --tags)
cd /usr/src && git clone https://github.com/nginx/njs.git
cd /usr/src/nginx
./configure --with-file-aio --with-cc-opt="-O3" --conf-path=/etc/nginx/nginx.conf \
    --add-module=/usr/src/nginx-vod-module \
    --add-module=/usr/src/njs/nginx \
    --with-http_auth_request_module --with-http_sub_module --with-http_ssl_module --with-debug \
    --error-log-path=/dev/stderr --http-log-path=/dev/stdout
make && make install
cd /
rm -rf /usr/src/*
