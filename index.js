const ZB = require('zeebe-node');
const fs = require('fs');

const cert = fs.readFileSync('./cert.pem')
const key = fs.readFileSync('./key.pem')

void (async () => {
	const zbc = new ZB.ZBClient('localhost:26500', {
		onReady,
		onConnectionError() {
			console.error('Connection error');
		},
		loglevel: 'DEBUG',
		useTLS: true,
		retry: false,
		customSSL: {
			rootCerts: cert,
			certChain: cert,
			privateKey: key
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
