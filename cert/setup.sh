#! /bin/bash

if [[ "$COMMON_NAME" = "" ]]; then
  echo "Missing environment variable <COMMON_NAME>"
  exit 1;
fi


### ROOT CA

# private key
openssl genrsa -out root.key.pem 4096

# certificate
openssl req -x509 \
            -new -days 365 -sha256 \
            -subj "/C=US/ST=California/L=Buxdehude/O=Camunda Example Corp/OU=Modeling/CN=Modeler Test Root CA" \
            -key root.key.pem \
            -out root.cert.pem


### INTERMEDIATE CA

# private key
openssl genrsa -out intermediate.key.pem 4096

cat > "intermediate.csr.conf" <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
crl_extensions = crl_ext

[ req ]
default_bits        = 2048
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_intermediate_ca

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ crl_ext ]
authorityKeyIdentifier=keyid:always
EOF

# signing request
openssl req -new -sha256 \
            -subj "/C=US/ST=California/L=Buxdehude/O=Camunda Example Corp/OU=Modeling/CN=Modeler Test Intermediate CA" \
            -key intermediate.key.pem \
            -out intermediate.csr.pem

# certificate
openssl x509 -req -sha256 -days 365 \
             -CAcreateserial \
             -extfile intermediate.csr.conf \
             -extensions v3_intermediate_ca \
             -in intermediate.csr.pem \
             -CA root.cert.pem -CAkey root.key.pem \
             -out intermediate.cert.pem

openssl verify -CAfile root.cert.pem intermediate.cert.pem

cat intermediate.cert.pem root.cert.pem > ca-chain.cert.pem


### SERVER

# private key
openssl genrsa -out server.key.pem 4096

cat > server.csr.conf <<EOF
[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
authorityKeyIdentifier = keyid,issuer
subjectAltName = @alt_names
subjectKeyIdentifier = hash

[ alt_names ]
DNS.1 = *.$COMMON_NAME

EOF

# signing request
openssl req -new -sha256 \
            -subj "/C=US/ST=California/L=Buxdehude/O=Camunda Example Corp/OU=Modeling/CN=$COMMON_NAME" \
            -key server.key.pem \
            -out server.csr.pem

# certificate
openssl x509 -req -sha256 -days 60 \
             -CAcreateserial \
             -extfile server.csr.conf \
             -extensions server_cert \
             -in server.csr.pem \
             -CA intermediate.cert.pem -CAkey intermediate.key.pem \
             -out server.cert.pem

openssl verify -CAfile ca-chain.cert.pem server.cert.pem

cat server.cert.pem intermediate.cert.pem > server-fullchain.cert.pem

echo "Generated certificate chain: [Root CA] -> [Intermediate CA] -> [Server certificate]"

# ensure certificates and private keys are readable,
# so docker does not complain. You'd NEVER do this in a
# production setup.
chmod o+r *.pem