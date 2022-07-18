# zeebe-tls-connection-test

This repo sets up a Zeebe instance with a self-signed certificate.

## Usage

### Requirements

* Docker
* openssl
* NodeJS
* npm

### Installation

```
npm ci
```

This will trigger the certificate generation.

### Running

In separate terminal windows run `npm run zeebe`, and after Zeebe instance is up, `npm start`.
This should connect to the Zeebe instance with the self-signed certificate, and print the topology.
