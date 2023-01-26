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
# ensure test.test.localhost resolves to 127.0.0.1
echo "127.0.0.1    test.test.localhost" | sudo tee -a /etc/hosts

# start zeebe with security enabled
docker-compose up zeebe

# test with security enabled
# won't work with existing certificate unless
# you test.test.localhost resolves to 127.0.0.1
ZEEBE_ADDRESS=test.test.localhost:26500 npm run test:secure
```

```sh
# start with security disabled
docker-compose --env-file .env.insecure up zeebe

# test with security disabled
npm run test:insecure

```sh
# to validate that the output is correct verify
# both the gateway version is produced twice, i.e. via
[ "$(npm run test:secure | grep '"gatewayVersion": "8.1.0"' -c)" = 2 ] || echo "error: missing output <gatewayVersion>"
```
