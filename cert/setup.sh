#! /bin/bash

if [[ "$COMMON_NAME" = "" ]]; then
  echo "Missing environment variable <COMMON_NAME>"
  exit 1;
fi

# Create root CA & Private key

openssl req -x509 \
            -sha256 -days 356 \
            -nodes \
            -newkey rsa:4096 \
            -subj "/CN=$COMMON_NAME/C=US/L=San Fransisco" \
            -keyout root.key.pem -out root.cert.pem

# Generate Private key

openssl genrsa -out server.key.pem 4096
openssl pkcs8 -topk8 -inform pem -in server.key.pem -outform pem -nocrypt -out server.cert.pem

# Create csf conf

cat > server.csr.conf <<EOF
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
O = TEST ORG
OU = TEST ORG Dev
CN = localhost

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = *.$COMMON_NAME

EOF

# create CSR request using private key

openssl req -new -key server.cert.pem -out server.csr -config server.csr.conf

# Create a external config file for the certificate

cat > server.cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.$COMMON_NAME

EOF

# Create SSl with self signed CA

openssl x509 -req \
    -in server.csr \
    -CA root.cert.pem -CAkey root.key.pem \
    -CAcreateserial -out server.crt \
    -days 365 \
    -sha256 -extfile server.cert.conf