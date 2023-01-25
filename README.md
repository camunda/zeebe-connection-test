# zeebe-tls-connection-test

This repo sets up a Zeebe instance with a self-signed certificate.

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

#### Prepare (generate certificates)

```sh
# generate certificates into ./cert
npm run generate-certs
```

#### Test in Docker

If successful you should see `zeebe-node` and `zbctl` print the current cluster topology.

```sh
# test with security enabled
docker-compose up

# test with security disabled
docker-compose --env-file .env.insecure up
```

#### Test locally (against running zeebe)

If successful you should see `zeebe-node` and `zbctl` print the current cluster topology.

```sh
# test with security enabled
# won't work with existing certificate unless
# you alias localhost to test.test.localhost in /etc/hosts
ZEEBE_ADDRESS=test.test.localhost:26500 npm run test:secure

# test with security disabled
npm run test:insecure
```
