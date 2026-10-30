const tls = require('node:tls');

let _cachedCertificates;

module.exports = getSystemCertificates;

/**
 * Get certificates from the system trust store.
 *
 * The bundled root certificates are included, too, as the result
 * is used in place of the defaults when establishing connections.
 *
 * @returns {Promise<string[]>}
 */
async function getSystemCertificates() {
	if (_cachedCertificates) {
		return _cachedCertificates;
	}

	_cachedCertificates = Array.from(new Set([
		...tls.getCACertificates('system'),
		...tls.getCACertificates('default')
	]));

	return _cachedCertificates;
}
