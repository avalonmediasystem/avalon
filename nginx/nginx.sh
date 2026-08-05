#!/bin/bash

# Make config file from template
[ -z "$AVALON_DOMAIN" ] && AVALON_DOMAIN="http://avalon"
[ -z "$AVALON_STREAMING_PORT" ] && AVALON_STREAMING_PORT=80
[ -z "$AVALON_STREAMING_BUCKET" ]
[ -z "$AVALON_STREAMING_BUCKET_URL" ] && AVALON_STREAMING_BUCKET_URL="http://$AVALON_STREAMING_BUCKET.s3.amazonaws.com/"
[ -z "$VOD_MODE" ] && VOD_MODE="remote"
[ -z "$S3_REGION" ] && S3_REGION="us-east-1"
[ -z "$S3_SERVER" ] && S3_SERVER="$AVALON_STREAMING_BUCKET.s3.amazonaws.com"
[ -z "$S3_AUTH" ] && S3_AUTH="false"
S3_AUTH=`echo "${S3_AUTH}" | tr '[:upper:]' '[:lower:]'`
if [[ $S3_AUTH == "true" ]]; then
  S3_AUTH="1"
else
  S3_AUTH="0"
fi

export AVALON_DOMAIN
export AVALON_STREAMING_PORT
export AVALON_STREAMING_BUCKET_URL
export VOD_MODE
export S3_REGION
export S3_SERVER
export S3_AUTH
envsubst '$AVALON_DOMAIN,$AVALON_STREAMING_PORT,$AVALON_STREAMING_BUCKET_URL,$VOD_MODE,$S3_SERVER,$S3_AUTH' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

exec /usr/local/nginx/sbin/nginx
