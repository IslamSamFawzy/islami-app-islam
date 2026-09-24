/// Upgrades a cleartext URL to HTTPS.
///
/// The mp3quran API hands out `http://` addresses for some stations and some
/// reciters' servers, and Android blocks cleartext traffic — those streams and
/// downloads simply fail. Every mp3quran audio host serves the same files over
/// TLS (checked against all ten `serverN.mp3quran.net` hosts the API returns),
/// so the scheme is rewritten rather than cleartext being allowed. A host that
/// somehow did not serve HTTPS would fail either way, so this cannot make
/// things worse.
///
/// Anything that is not `http://` — HTTPS already, a local file path, an empty
/// string — is returned untouched.
String secureUrl(String url) =>
    url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;
