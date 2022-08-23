#!/usr/bin/env bash

/usr/local/opt/openssl/bin/openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 365 --nodes -subj "/CN=localhost"