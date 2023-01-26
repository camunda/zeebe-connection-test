# zeebe-connection-test

[![CI](https://github.com/camunda/zeebe-connection-test/actions/workflows/CI.yml/badge.svg)](https://github.com/camunda/zeebe-connection-test/actions/workflows/CI.yml)

This repo provides the utilities to verify connection against a running (remote) Zeebe instance.

It allows you to cover different cases, including secure communication to Zeebe. Bring your own certificates or use provided facilities to generate a root certificate as well as a self-signed certificate / private key used by the Zeebe server.

## Requirements

* Docker
* openssl
* NodeJS
* npm

## Installation

```sh
npm install
```

## Usage

### Configure certificates

You can bring your own root certificate + server certificate / private key pair and store them in `./cert` in the following format:

```sh
# ./cert/root.crt   - root certificate
# ./cert/server.crt - server certificate
# ./cert/server.key - server private key
```

Alternatively use the contained script to generate them for a particular `COMMON_NAME`.

#### Inputs

| Name | Description |
| :--- | :--- |
| `COMMON_NAME` | Common name used in the generated server (wildcard) certificate. `ZEEBE_HOSTNAME`, the servers publicly visible host name must be a sub-domain of this common name matching `*.COMMON_NAME` (one level deep). |

#### Script
 
```sh
# generate root certificate and server cert + private key into ./cert
#
# the server certificate has the wildcard pattern *.COMMON_NAME configured as an ALT_NAME
COMMON_NAME=example.com npm run generate-certs
```

### Test in Docker

#### Inputs

| Name | Description |
| :--- | :--- |
| `ZEEBE_HOSTNAME` | Name under which the Zeebe instance is available in the network. |


#### Script

If successful you should see `zeebe-node` and `zbctl` print the current cluster topology.

```sh
# test with security enabled
ZEEBE_HOSTNAME=sub.example.com docker-compose up

# test with security disabled
ZEEBE_HOSTNAME=sub.example.com docker-compose --env-file .env.insecure up
```

### Test locally, secured with TLS

#### Inputs

| Name | Description |
| :--- | :--- |
| `ZEEBE_HOSTNAME` | Name under which the Zeebe instance is available in the network. A valid hostnam must match the server certificates `COMMON_NAME` or configured wildcard pattern (i.e. `*.COMMON_NAME`) one level deep. |
| `ZEEBE_ADDRESS` | Address to connect to, typically `ZEEBE_HOSTNAME:26500` |

#### Script

If successful you should see `zeebe-node` and `zbctl` print the current cluster topology.

```sh
# (once) ensure the configured hostname resolves to 127.0.0.1
ZEEBE_HOSTNAME=sub.example.com sh -c 'echo "127.0.0.1    $ZEEBE_HOSTNAME"' | sudo tee -a /etc/hosts

# start zeebe with security enabled
ZEEBE_HOSTNAME=sub.example.com docker-compose up zeebe

# test with security enabled
ZEEBE_ADDRESS=sub.example.com:26500 npm run test:secure
```

To test with the [Camunda Modeler](https://github.com/camunda/camunda-modeler) pass the custom SSL root certificate through the use the `--zeebe-ssl-certificate` flag:

```sh
camunda-modeler --zeebe-ssl-certificate=cert/root.crt
```

### Test locally, unsecured

#### Inputs

| Name | Description |
| :--- | :--- |
| `ZEEBE_HOSTNAME` | Name under which the Zeebe instance is available in the network. |
| `ZEEBE_ADDRESS` | Address to connect to, typically `ZEEBE_HOSTNAME:26500` |

#### Script

```sh
# (once) ensure the configured hostname resolves to 127.0.0.1
ZEEBE_HOSTNAME=sub.example.com sh -c 'echo "127.0.0.1    $ZEEBE_HOSTNAME"' | sudo tee -a /etc/hosts

# start with security disabled
ZEEBE_HOSTNAME=sub.example.com docker-compose --env-file .env.insecure up zeebe

# test with security disabled
ZEEBE_ADDRESS=sub.example.com:26500 npm run test:insecure
```

### Programmatically validate the output

Assert the correct output, i.e. by verifying correct cluster topology logs:

```sh
# the gateway version is produced twice as we test against `zebee-node` and `zbctl` 
[ "$(npm run test:secure | grep '"gatewayVersion": "8.1.0"' -c)" = 2 ] || echo "error: missing output <gatewayVersion>"
```


### What else?

There is a couple of things you can validate with the existing setup:

* Verify pairs of certificates work
* Verify different zeebe clients work
* Verify certificates work in combination with a given host name
