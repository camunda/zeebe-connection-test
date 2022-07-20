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

From [`b7f2357`](https://github.com/barmac/zeebe-tls-connection-test/commit/b7f23576b60094211ccf61fae1e0ee9a349f4cba) on, the certificate needs to be added
to the system keychain for the test to succeed.

### Running

In separate terminal windows run `npm run zeebe`, and after Zeebe instance is up, `npm start`.
This should connect to the Zeebe instance with the self-signed certificate, and print the topology.
