#!/usr/bin/env bash
set -euo pipefail

ca_key_size="${CA_KEY_SIZE:-4096}"
ca_cert_expiry="${CA_CERT_EXPIRY:-3650}"

if [[ "$#" -lt 1 ]]; then
    echo "no domains provided. please provide at least one domain to the command. note the first domain may not be a wildcard"
    echo "usage: $0 <domain>+"
    exit 1
fi
if [[ "$1" == *'*'* ]]; then
    echo "first domain may not contain a wildcard"
    exit 1
fi
# create the certificate name list
subjectAltNames=""
export baseAltName="$1"
for domain in "$@"; do
    subjectAltNames="$subjectAltNames,DNS:$domain"
done
export subjectAltNames="${subjectAltNames:1}"

# set up directory structure
mkdir -p ca/{certs,private}
if [[ -f ca/index.txt ]]; then
    echo "index file already exists, skipping"
else
    touch ca/index.txt
    echo "created index file"
fi
if [[ -f ca/serial ]]; then
    echo "serial file already exists, skipping"
else
    openssl rand -hex 16 > ca/serial
    echo "created serial file"
fi

# create ca key
if [[ -f ca/private/key.pem ]]; then
    echo "ca key already exists, skipping"
else
    echo "generating ca key"
    openssl genrsa -des3 -out ca/private/key.pem "$ca_key_size"
fi

if [[ ! -f ca/ca.csr ]]; then
    echo "creating new csr"
    openssl req \
        -new \
        -config openssl.cnf \
        -key ca/private/key.pem \
        -out ca/ca.csr
fi
if [[ ! -f ca/ca.crt ]]; then
    echo "signing root certificate"
    openssl ca \
        -selfsign \
        -config openssl.cnf \
        -extensions ca_extensions \
        -days "$ca_cert_expiry" \
        -keyfile ca/private/key.pem \
        -in ca/ca.csr \
        -out ca/ca.crt
    rm ca/ca.csr
else
    echo "root certificate already exists, skipping"
fi

mkdir -p ca/"$baseAltName"
openssl genrsa -out ca/"$baseAltName"/"$baseAltName".key 2048

openssl req \
    -new \
    -config openssl.cnf \
    -addext "subjectAltName=$subjectAltNames" \
    -key ca/"$baseAltName"/"$baseAltName".key \
    -out ca/"$baseAltName"/"$baseAltName".csr

openssl ca \
    -config openssl.cnf \
    -extensions leaf_extensions \
    -keyfile ca/private/key.pem \
    -in ca/"$baseAltName"/"$baseAltName".csr \
    -out ca/"$baseAltName"/"$baseAltName".crt
