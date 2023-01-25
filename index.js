const ZB = require('zeebe-node');

const fs = require('fs');

async function run() {

	const useTLS = process.env.ZEEBE_INSECURE_CONNECTION === 'false';
	const address = process.env.ZEEBE_ADDRESS;

	const certsPath = process.env.ZEEBE_CA_CERTIFICATE_PATH;
	const loglevel = process.env.LOG_LEVEL || 'info';

	const customSSL = certsPath && {
		rootCerts: fs.readFileSync(certsPath)
	};

	console.log(`
		executing zeebe-node with config:

			address   = ${ address }
			useTLS    = ${ useTLS }
			certsPath = ${ certsPath }
			loglevel  = ${ loglevel }
	`);

  const zbc = new ZB.ZBClient(address, {
  	loglevel,
  	customSSL,
  	useTLS,
		retry: false
  });

  const topology = await zbc.topology();

	console.log(JSON.stringify(topology, null, 2))
}

run().catch(err => {
  console.error('zbc:error', err);

  process.exit(1);
}).finally(() => {
	console.log('done');
});
