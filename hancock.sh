#!/usr/bin/env bash
set -euo pipefail

# set up directory structure
mkdir -p ca/{certs,private,reqs}
[ -f ca/index.txt ] || touch ca/index.txt
[ -f ca/serial ] || openssl rand -hex 16 > ca/serial

