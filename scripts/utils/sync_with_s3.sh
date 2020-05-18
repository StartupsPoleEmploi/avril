#!/bin/bash

if ! [ -x "$(command -v mc)" ]; then
  wget -P /usr/bin https://dl.min.io/client/mc/release/linux-amd64/mc
  chmod +x /usr/bin/mc
else
  /usr/bin/mc update
fi

/usr/bin/mc config host add s3 https://s3.amazonaws.com $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY --api S3v4

mc mirror s3/$BUCKET_NAME/$BUCKET_NAME minio/$BUCKET_NAME

mix MigrateS3ToMinio