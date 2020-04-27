#!/bin/bash

/usr/bin/mc config host add s3 https://s3.amazonaws.com $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY --api S3v4

mc mirror s3/$BUCKET_NAME/$BUCKET_NAME minio/$BUCKET_NAME

mix MigrateS3ToMinio