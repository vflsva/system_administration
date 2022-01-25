#!/bin/bash

# generate ssl certs for use with ansible 
# (run on ansible control host)

# set username (one to be used on windows host)
WINUSERNAME="ansible"

# create openssl.conf 
cat > openssl.conf << EOL
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req_client]
extendedKeyUsage = clientAuth
subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:$WINUSERNAME@localhost
EOL

# set config file for openssl
export OPENSSL_CONF=openssl.conf

# create cert
 openssl req -x509 -nodes \
    -days 3650 -newkey rsa:2048 \
    -out ./certs/ansible_cert.pem \
    -outform PEM \
    -keyout ./certs/ansible_cert_key.pem \
    -subj "/CN=$WINUSERNAME" \
    -extensions \
    v3_req_client