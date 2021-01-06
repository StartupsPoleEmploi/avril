#!/bin/bash

delegates=${1?:"delegates.csv required"}
mailjet=${2?:"mailjet.csv required"}
extract="extract.csv"

head -n 1 $mailjet >> $extract

for email in $(csvtool -t ',' col 11 $delegates | uniq); do
  echo "Filtering $email"
  awk -F, -v email="$email" '$2 == email {print}' $mailjet >> $extract
done