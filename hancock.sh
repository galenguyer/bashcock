#!/usr/bin/env bash
set -euo pipefail

ca_key_size="${CA_KEY_SIZE:-4096}"
ca_cert_expiry="${CA_CERT_EXPIRY:-3650}"

# set up directory structure
mkdir -p ca/{certs,private,reqs}
if [ -f ca/index.txt ]; then
    echo "index file already exists, skipping"
else
    touch ca/index.txt
    echo "created index file"
fi
if [ -f ca/serial ]; then
    echo "serial file already exists, skipping"
else
    openssl rand -hex 16 > ca/serial
    echo "created serial file"
fi

# create ca key
if [ -f ca/private/key.pem ]; then
    echo "ca key already exists, skipping"
else
    echo "generating ca key"
    openssl genrsa -des3 -out ca/private/key.pem "$ca_key_size"
fi
