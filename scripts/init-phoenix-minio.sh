#!/bin/sh

if ! [ -x "$(command -v mc)" ]; then
  wget -P /usr/bin https://dl.min.io/client/mc/release/linux-amd64/mc
  chmod +x /usr/bin/mc
else
  /usr/bin/mc update
fi

/usr/bin/mc config host add minio http://minio:9000 $MINIO_ACCESS_KEY $MINIO_SECRET_KEY --api S3v4
/usr/bin/mc mb minio/$BUCKET_NAME
/usr/bin/mc policy set download minio/$BUCKET_NAME

