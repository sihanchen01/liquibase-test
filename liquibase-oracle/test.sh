#!/bin/bash -l

set -x

LOGLEVEL=($1:"info")
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)

mkdir -p test_logs
liquibase --loglevel="$LOGLEVEL" update 2>&1 | tee "test_logs/test-$TIMESTAMP.log"
