# zeebe-connection-test

[![CI](https://github.com/camunda/zeebe-connection-test/actions/workflows/CI.yml/badge.svg)](https://github.com/camunda/zeebe-connection-test/actions/workflows/CI.yml)

This repo provides the utilities to verify connection against a running (remote) Zeebe instance.

It allows you to cover different cases, including secure communication to Zeebe, configured through a self-signed certificate.

## Usage

### Requirements

* Docker
* openssl
* NodeJS
* npm

### Installation

```sh
npm install
```

### Usage

#### Generate certificates

```sh
# generate the following files into ./cert
#
# ./cert/root.crt   - root certificate
# ./cert/server.crt - server certificate
# ./cert/server.key - server private key
#
# server.crt has *.COMMON_NAME as an ALT_NAME configured
#
COMMON_NAME=example.com npm run generate-certs
```

#### Test in Docker

If successful you should see `zeebe-node` and `zbctl` print the current cluster topology.

```sh
# test with security enabled
ZEEBE_HOSTNAME=sub.example.com docker-compose up

# test with security disabled
docker-compose --env-file .env.insecure up
```

#### Test locally (against running zeebe)

If successful you should see `zeebe-node` and `zbctl` print the current cluster topology.

```sh
# ensure sub.example.com resolves to 127.0.0.1
ZEEBE_HOSTNAME=sub.example.com sh -c 'echo "127.0.0.1    $ZEEBE_HOSTNAME"' | sudo tee -a /etc/hosts

# start zeebe with security enabled
ZEEBE_HOSTNAME=sub.example.com docker-compose up zeebe

# test with security enabled
# won't work with existing certificate unless
# you sub.example.com resolves to 127.0.0.1
ZEEBE_ADDRESS=sub.example.com:26500 npm run test:secure
```

To test with the [Camunda Modeler](https://github.com/camunda/camunda-modeler) pass the custom SSL root certificate through the use the `--zeebe-ssl-certificate` flag:

```sh
camunda-modeler --zeebe-ssl-certificate=cert/rootCA.crt
```

```sh
# start with security disabled
ZEEBE_HOSTNAME=sub.example.com docker-compose --env-file .env.insecure up zeebe

# test with security disabled
ZEEBE_ADDRESS=sub.example.com:26500 npm run test:insecure

```sh
# to validate that the output is correct verify
# both the gateway version is produced twice, i.e. via
[ "$(npm run test:secure | grep '"gatewayVersion": "8.1.0"' -c)" = 2 ] || echo "error: missing output <gatewayVersion>"
```

#### What else?

There is a couple of things you can validate with the existing setup:

* Verify pairs of certificates work
* Verify different zeebe clients work
* Verify certificates work in combination with a given host name