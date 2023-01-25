const ZB = require('zeebe-node');

const fs = require('fs');

process.on('uncaughtException', error => {
	console.error('uncaughtException', error);
});


async function run() {

	const useTLS = process.env.ZEEBE_INSECURE_CONNECTION === 'false';
	const address = process.env.ZEEBE_ADDRESS || 'localhost:26500';

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

  console.debug('pre-topology');

  const topology = await zbc.topology();

  console.debug('post-topology');

	console.log(JSON.stringify(topology, null, 2))
}

run().catch(err => {
  console.error('error', err);

  process.exit(1);
});
