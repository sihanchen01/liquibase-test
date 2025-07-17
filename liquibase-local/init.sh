#!/bin/bash
set -euo pipefail
set -x # Print each command as it's executed

WORKDIR=$(pwd)

# Clean up and set up test directory
rm -rf liquibase-test
pkill -f "h2" || true
mkdir liquibase-test
mkdir -p log

cd test

# Initialize Liquibase project (auto-confirm with 'Y' for defaults)
printf "Y\n" | liquibase init project

# Initialize H2 database (auto-confirm with 'Y')
printf "Y\n" | liquibase init start-h2 >"$WORKDIR/log/liquibase-h2-$(date +%Y%m%d-%H%M%S).log" 2>&1 &
