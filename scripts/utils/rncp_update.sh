#!/bin/bash

TODAY=$(date '+%Y-%m-%d')
FILENAME="export_fiches_RNCP_V2_0_$TODAY"
ZIP_FILENAME="$FILENAME.zip"
XML_FILENAME="$FILENAME.xml"
XML_FILEPATH=${1:-"./priv/$XML_FILENAME"}

cd "$(dirname "$0")/../.."

if [ -f $XML_FILEPATH ]; then
  echo "[info] $XML_FILENAME already here, cleaning former xml files and starting ..."
  # find ./priv/*.xml -type f -not -name "$XML_FILENAME" -print0 | xargs -0 -I {} rm -v {}
else
  echo "[info] $XML_FILENAME missing. Downloading ..."
  sshpass -p $RNCP_PASS sftp -o StrictHostKeyChecking=no -P $RNCP_PORT $RNCP_USERNAME@$RNCP_HOST:/xml_export/$ZIP_FILENAME /tmp
  echo "[info] $XML_FILENAME downloaded. Unziping"
  unzip /tmp/$ZIP_FILENAME -d ./priv/
  echo "[info] $XML_FILENAME unzipped."
  if [ -f $XML_FILEPATH ]; then
    rm -v /tmp/*.zip
    echo "[info] $XML_FILENAME downloaded and extracted, starting ..."
  else
    echo "[error] $XML_FILENAME could not be downloaded, exiting..."
    exit 1;
  fi
fi


read -p "Let's import with this file $XML_FILENAME ? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  ./scripts/wait-for-postgres.sh && \
  mix ecto.migrate && \
  POSTGRES_TIMEOUT=500000 \
  mix RncpUpdate -f $XML_FILEPATH
fi
