const { Camunda8 } = require('@camunda8/sdk');

process.on('uncaughtException', error => {
	console.error('uncaughtException', error);
});


async function run() {

	const useTLS = process.env.ZEEBE_INSECURE_CONNECTION === 'false';
	const address = process.env.ZEEBE_ADDRESS || 'localhost:26500';

	const certsPath = process.env.ZEEBE_CA_CERTIFICATE_PATH;
	const loglevel = process.env.LOG_LEVEL || 'info';

	console.log(`
		executing @camunda8/sdk with config:

			ZEEBE_ADDRESS                 = ${address}
			CAMUNDA_SECURE_CONNECTION     = ${useTLS}
			CAMUNDA_CUSTOM_ROOT_CERT_PATH = ${certsPath}
			ZEEBE_CLIENT_LOG_LEVEL        = ${loglevel}
	`);

	const c8 = new Camunda8({
		ZEEBE_ADDRESS: address,
		CAMUNDA_SECURE_CONNECTION: useTLS,
		CAMUNDA_CUSTOM_ROOT_CERT_PATH: certsPath,
		ZEEBE_CLIENT_LOG_LEVEL: loglevel,
		ZEEBE_GRPC_CLIENT_RETRY: false,
		CAMUNDA_OAUTH_DISABLED: true
	});

	const client = c8.getZeebeGrpcApiClient();

	console.debug('pre-topology');

	const topology = await client.topology();

	console.debug('post-topology');

	console.log(JSON.stringify(topology, null, 2))
}

run().catch(err => {
	console.error('error', err);

	process.exit(1);
});
