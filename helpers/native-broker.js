#!/usr/bin/env node

/**
 * Run the Camunda distribution (broker only) as a native process,
 * for platforms that cannot run Linux containers (macOS, Windows).
 *
 * Mirrors the broker setup of docker-compose.yml. Requires Java 21+
 * and the certificates in ./cert (cf. `npm run generate-certs`).
 *
 * Usage:
 *
 *   node helpers/native-broker.js start <distribution> [--insecure]
 *   node helpers/native-broker.js stop <distribution>
 *
 * Ports, as in docker-compose.yml: ZEEBE_PORT (gRPC, default 26500),
 * ZEEBE_REST_PORT (REST, default 8080) and ZEEBE_MANAGEMENT_PORT
 * (health, default 9600).
 */

const { spawn, execFileSync } = require('node:child_process');
const fs = require('node:fs');
const net = require('node:net');
const path = require('node:path');

const isWindows = process.platform === 'win32';

const GRPC_PORT = process.env.ZEEBE_PORT || '26500';
const REST_PORT = process.env.ZEEBE_REST_PORT || '8080';
const MANAGEMENT_PORT = process.env.ZEEBE_MANAGEMENT_PORT || '9600';

const READY_URL = `http://localhost:${ MANAGEMENT_PORT }/actuator/health/readiness`;
const READY_TIMEOUT = 180 * 1000;

const [ command, distribution, ...flags ] = process.argv.slice(2);

if (!distribution || ![ 'start', 'stop' ].includes(command)) {
	console.error('usage: native-broker.js start|stop <distribution> [--insecure]');

	process.exit(1);
}

const distributionDir = path.resolve(distribution);
const pidFile = path.join(distributionDir, 'broker.pid');
const logFile = path.join(distributionDir, 'broker.log');
const dataDir = path.join(distributionDir, 'data');

const run = command === 'start' ? start : stop;

run().catch(err => {
	console.error(err.message);

	process.exit(1);
});

async function start() {
	const secure = !flags.includes('--insecure');

	const certificate = cert('server.cert.pem');
	const privateKey = cert('server.key.pem');

	// another broker answering on the ports would pass for ours
	for (const port of [ GRPC_PORT, REST_PORT, MANAGEMENT_PORT ]) {
		if (!await isPortFree(Number(port))) {
			throw new Error(`port ${ port } is already in use`);
		}
	}

	const env = {
		...process.env,
		ZEEBE_BROKER_NETWORK_HOST: '0.0.0.0',
		ZEEBE_BROKER_GATEWAY_NETWORK_PORT: GRPC_PORT,
		SERVER_PORT: REST_PORT,
		MANAGEMENT_SERVER_PORT: MANAGEMENT_PORT,
		ZEEBE_BROKER_GATEWAY_SECURITY_ENABLED: String(secure),
		ZEEBE_BROKER_GATEWAY_SECURITY_CERTIFICATECHAINPATH: certificate,
		ZEEBE_BROKER_GATEWAY_SECURITY_PRIVATEKEYPATH: privateKey,
		SERVER_SSL_ENABLED: String(secure),
		SERVER_SSL_CERTIFICATE: `file:${ certificate }`,
		SERVER_SSL_CERTIFICATE_PRIVATE_KEY: `file:${ privateKey }`,
		SPRING_PROFILES_ACTIVE: 'broker',
		CAMUNDA_DATA_SECONDARYSTORAGE_TYPE: 'none',
		CAMUNDA_SECURITY_AUTHENTICATION_UNPROTECTEDAPI: 'true'
	};

	fs.rmSync(dataDir, { recursive: true, force: true });

	const log = fs.openSync(logFile, 'w');

	const bin = path.join(distributionDir, 'bin', isWindows ? 'camunda.bat' : 'camunda');

	const child = spawn(isWindows ? `"${ bin }"` : bin, [], {
		cwd: distributionDir,
		env,
		detached: true,
		shell: isWindows,
		stdio: [ 'ignore', log, log ],
		windowsHide: true
	});

	let exitCode;

	child.on('exit', code => exitCode = code ?? -1);
	child.unref();

	fs.writeFileSync(pidFile, String(child.pid));

	console.log(`starting broker <${ child.pid }> (${ secure ? 'secure' : 'insecure' })`);

	const deadline = Date.now() + READY_TIMEOUT;

	while (Date.now() < deadline) {
		if (exitCode !== undefined) {
			throw new Error(`broker exited with code ${ exitCode }, see ${ logFile }`);
		}

		if (await isReady()) {
			console.log('broker is ready');

			return;
		}

		await sleep(1000);
	}

	throw new Error(`broker not ready after ${ READY_TIMEOUT / 1000 }s, see ${ logFile }`);
}

async function stop() {
	if (!fs.existsSync(pidFile)) {
		return;
	}

	const pid = Number(fs.readFileSync(pidFile, 'utf8'));

	terminate(pid, 'SIGTERM');

	for (let i = 0; i < 20 && isRunning(pid); i++) {
		await sleep(500);
	}

	if (isRunning(pid)) {
		terminate(pid, 'SIGKILL');
	}

	fs.rmSync(pidFile, { force: true });

	console.log(`stopped broker <${ pid }>`);
}


// helpers ////////////////

function cert(name) {
	return path.resolve('cert', name).replace(/\\/g, '/');
}

function terminate(pid, signal) {
	try {
		if (isWindows) {
			execFileSync('taskkill', [ '/pid', String(pid), '/T', '/F' ], { stdio: 'ignore' });
		} else {

			// signal the process group, we started the broker detached
			process.kill(-pid, signal);
		}
	} catch (err) {

		// already gone
	}
}

function isPortFree(port) {
	return new Promise(resolve => {
		const server = net.createServer();

		server.once('error', () => resolve(false));
		server.once('listening', () => server.close(() => resolve(true)));
		server.listen(port, '0.0.0.0');
	});
}

async function isReady() {
	try {
		const response = await fetch(READY_URL, { signal: AbortSignal.timeout(2000) });

		return response.ok;
	} catch (err) {
		return false;
	}
}

function isRunning(pid) {
	try {
		process.kill(pid, 0);

		return true;
	} catch (err) {
		return false;
	}
}

function sleep(ms) {
	return new Promise(resolve => setTimeout(resolve, ms));
}
