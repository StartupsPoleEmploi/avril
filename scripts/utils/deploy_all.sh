#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

$DIR/deploy_local.sh --need-change avril-livret1 && \
$DIR/deploy_local.sh --need-change avril
