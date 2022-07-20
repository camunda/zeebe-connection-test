const ZB = require('zeebe-node');

const getSystemCertificates = require('./get-system-certificates');

void (async () => {
	const systemCertificates = await getSystemCertificates();

	const zbc = new ZB.ZBClient('localhost:26500', {
		onReady,
		onConnectionError() {
			console.error('Connection error');
		},
		loglevel: 'DEBUG',
		useTLS: true,
		retry: false,
		customSSL: {
			// For untrusted cert, use
			// rootCerts: require('fs').readFileSync('./cert.pem'),
			rootCerts: Buffer.from(systemCertificates.join('\n'))
		}
	});

	await printTopology();

	function onReady() {
		console.log(`Connected!`);
	}

	async function printTopology() {
		try {
			const topology = await zbc.topology();
			console.log('Topology:', JSON.stringify(topology, null, 2));
		} catch (error) {
			console.error('Couldn\'t get topology', error);
		}
	}
})();
