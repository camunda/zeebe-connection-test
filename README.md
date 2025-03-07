# zeebe-connection-test

[![CI](https://github.com/camunda/zeebe-connection-test/actions/workflows/CI.yml/badge.svg)](https://github.com/camunda/zeebe-connection-test/actions/workflows/CI.yml)

This repo provides the utilities to test connections (secure and insecure) to a running (remote) Zeebe instance.

To test secure communication [bring your own certificates](#configure-certificates) or [generate what you need](#generate-certificates) to communicate with Zeebe securely.

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

Use this package to perform various tests and test preparations:

* [Configure certificates](#configure-certificates)
* [Generate certificates](#generate-certificates)
* [Test: Secure connection to Zeebe](#test-secure-connection-to-zeebe)
* [Test: Secure connection to Zeebe via reverse proxy](#test-secure-connection-to-zeebe-via-reverse-proxy)
* [Test: Insecure connection to Zeebe](#test-insecure-connection-to-zeebe)


## Configure certificates

You can bring your own root certificate + server certificate / private key pair and store them in `./cert` in the following format:

```sh
# ./cert/root.cert.pem                - root certificate
# ./cert/ca-chain.cert.pem            - root + intermediate certificate chain
# ./cert/server.cert.pem              - server certificate
# ./cert/server-fullchain.cert.pem    - server certificate + full chain
# ./cert/server.key.pem               - server private key
```

Alternatively use the [contained script](#generate-certificates) to generate them for a particular `COMMON_NAME`.

## Generate certificates

Generate a chain of trust, private keys and certificates for a particular `COMMON_NAME`.

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


## Test: Secure connection to Zeebe

In this test we securely connect our client to a Zeebe instance via TLS. We validate the Zeebe server certificate through a shared chain of trust as we establish the connection.

#### Inputs

| Name | Description |
| :--- | :--- |
| `ZEEBE_HOSTNAME` | Name under which the Zeebe instance is available in the network. A valid hostname must match the server certificates `COMMON_NAME` or configured wildcard pattern (i.e. `*.COMMON_NAME`) one level deep. |
| `ZEEBE_PORT` | Port under which the Zeebe gateway is available, default is `26500` |
| `ZEEBE_ADDRESS` | Address to connect to, typically `ZEEBE_HOSTNAME:ZEEBE_PORT` |

#### Script

If successful you should see `zeebe-node`, `zbctl`, and `@camunda8/sdk` print the current cluster topology.

```sh
# (once) ensure the configured hostname resolves to 127.0.0.1
ZEEBE_HOSTNAME=sub.example.com sh -c 'echo "127.0.0.1    $ZEEBE_HOSTNAME"' | sudo tee -a /etc/hosts

# start zeebe with security enabled
ZEEBE_HOSTNAME=sub.example.com docker compose up zeebe

# test with security enabled
ZEEBE_ADDRESS=sub.example.com:26500 npm run test:secure
```

To test with the [Camunda Modeler](https://github.com/camunda/camunda-modeler) pass the custom SSL root certificate use the `--zeebe-ssl-certificate` flag:

```sh
camunda-modeler --zeebe-ssl-certificate=cert/ca-chain.cert.pem
```


## Test: Secure connection to Zeebe via reverse proxy

> **Note:** This is a variation of [securely connecting](#test-secure-connection-to-zeebe), just so that Zeebe is hidden behind a [reverse proxy](https://www.cloudflare.com/learning/cdn/glossary/reverse-proxy/).

In this test we securely connect our client to a [reverse proxy](https://www.cloudflare.com/learning/cdn/glossary/reverse-proxy/) via TLS. That proxy terminates the secured connection and forwards traffic to Zeebe gateway in plain text. We validate the proxy server certificate through a shared chain of trust as we establish the connection.

#### Inputs

| Name | Description |
| :--- | :--- |
| `ZEEBE_HOSTNAME` | Name under which the Zeebe instance and reverse proxy are available in the network. A valid hostname must match the server certificates `COMMON_NAME` or configured wildcard pattern (i.e. `*.COMMON_NAME`) one level deep. |
| `PROXY_PORT` | Port under which the reverse proxy is available, default is `443` |
| `ZEEBE_PORT` | Port under which the Zeebe gateway is available, default is `26500` |
| `ZEEBE_ADDRESS` | Address to connect to, typically `ZEEBE_HOSTNAME:PROXY_PORT` |

#### Script

If successful you should see `zeebe-node` and `zbctl` print the current cluster topology.

```sh
# (once) ensure the configured hostname resolves to 127.0.0.1
ZEEBE_HOSTNAME=sub.example.com sh -c 'echo "127.0.0.1    $ZEEBE_HOSTNAME"' | sudo tee -a /etc/hosts

# start zeebe with security enabled
ZEEBE_HOSTNAME=sub.example.com docker compose --env-file .env.proxy up zeebe proxy

# test with security enabled
ZEEBE_ADDRESS=sub.example.com:443 npm run test:secure
```

To test with the [Camunda Modeler](https://github.com/camunda/camunda-modeler) pass the custom SSL root certificate use the `--zeebe-ssl-certificate` flag:

```sh
camunda-modeler --zeebe-ssl-certificate=cert/ca-chain.cert.pem
```


## Test: Insecure connection to Zeebe

In this test we connect to Zeebe in an insecure (plain text) fashion.

#### Inputs

| Name | Description |
| :--- | :--- |
| `ZEEBE_HOSTNAME` | Name under which the Zeebe instance is available in the network. |
| `ZEEBE_PORT` | Port under which the Zeebe gateway is available, default is `26500` |
| `ZEEBE_ADDRESS` | Address to connect to, typically `ZEEBE_HOSTNAME:ZEEBE_PORT` |

#### Script

```sh
# (once) ensure the configured hostname resolves to 127.0.0.1
ZEEBE_HOSTNAME=sub.example.com sh -c 'echo "127.0.0.1    $ZEEBE_HOSTNAME"' | sudo tee -a /etc/hosts

# start with security disabled
ZEEBE_HOSTNAME=sub.example.com docker compose --env-file .env.insecure up zeebe

# test with security disabled
ZEEBE_ADDRESS=sub.example.com:26500 npm run test:insecure
```


## Test in Docker

#### Inputs

| Name | Description |
| :--- | :--- |
| `ZEEBE_HOSTNAME` | Name under which the Zeebe instance is available in the network. |
| `ZEEBE_PORT` | Portunder which the Zeebe gateway is available, default is `26500` |


#### Script

If successful you should see `zeebe-node`, `zbctl`, and `@camunda8/sdk` print the current cluster topology.

```sh
# test with security enabled
ZEEBE_HOSTNAME=sub.example.com docker compose up

# test with security disabled
ZEEBE_HOSTNAME=sub.example.com docker compose --env-file .env.insecure up
```


## Programmatically validate the output

Assert the correct output, i.e. by verifying correct cluster topology logs:

```sh
# the gateway version is produced twice as we test against `zebee-node` and `zbctl`
[ "$(npm run test:secure | grep '"gatewayVersion": "8.1.0"' -c)" = 2 ] || echo "error: missing output <gatewayVersion>"
```


## What else?

There is a couple of things you can validate with the existing setup:

* Verify pairs of certificates work
* Verify different zeebe clients work
* Verify certificates work in combination with a given host name
