#! /bin/bash

# Create root CA & Private key

openssl req -x509 \
            -sha256 -days 356 \
            -nodes \
            -newkey rsa:4096 \
            -subj "/CN=test.localhost/C=US/L=San Fransisco" \
            -keyout rootCA.key -out rootCA.crt

# Generate Private key

openssl genrsa -out cert.key 4096
openssl pkcs8 -topk8 -inform pem -in cert.key -outform pem -nocrypt -out key.pem

# Create csf conf

cat > csr.conf <<EOF
[ req ]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = California
L = San Fransisco
O = MLopsHub
OU = MlopsHub Dev
CN = localhost

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = *.test.localhost

EOF

# create CSR request using private key

openssl req -new -key key.pem -out server.csr -config csr.conf

# Create a external config file for the certificate

cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.test.localhost

EOF

# Create SSl with self signed CA

openssl x509 -req \
    -in server.csr \
    -CA rootCA.crt -CAkey rootCA.key \
    -CAcreateserial -out cert.pem \
    -days 365 \
    -sha256 -extfile cert.conf