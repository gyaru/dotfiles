// user.js
// plenty of inspiration taken from pyllyukko/user.js & ghacksuserjs/ghacks-user.js

// disable startup garbage
user_pref("browser.slowStartup.notificationDisabled", true);
user_pref("browser.slowStartup.maxSamples", 0);
user_pref("browser.slowStartup.samples", 0);
user_pref("browser.rights.3.shown", true);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("startup.homepage_override_url", ""); // what's new page after updates
user_pref("browser.laterrun.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);

// increase back button history
user_pref("browser.sessionstore.max_serialize_back",			500);

// force new windows to be in tabs
user_pref("browser.link.open_newwindow.restriction",			0);

// When geolocation is enabled, use Mozilla geolocation service instead of Google
user_pref("geo.wifi.uri", "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%");

// When geolocation is enabled, don't log geolocation requests to the console
user_pref("geo.wifi.logging.enabled", false);

// Don't reveal your internal IP when WebRTC is enabled (Firefox >= 42)
user_pref("media.peerconnection.ice.default_address_only",	true); // Firefox 42-51
user_pref("media.peerconnection.ice.no_host",			true); // Firefox >= 52

// Disable battery API (Firefox < 52)
user_pref("dom.battery.enabled",				false);

// Set Accept-Language HTTP header to en-US regardless of Firefox localization
user_pref("intl.accept_languages",				"en-us, en");

// Set Firefox locale to en-US
user_pref("general.useragent.locale",				"en-US");

// Don't use OS values to determine locale, force using Firefox locale setting
user_pref("intl.locale.matchOS",				false);

// Don't use Mozilla-provided location-specific search engines
user_pref("browser.search.geoSpecificDefaults",			false);

// Don't try to guess domain names when entering an invalid domain name in URL bar
user_pref("browser.fixup.alternate.enabled",			false);

// Send DNS request through SOCKS when SOCKS proxying is in use
user_pref("network.proxy.socks_remote_dns",			true);

// Don't monitor OS online/offline connection state
user_pref("network.manage-offline-status",			false);

// Disable JAR from opening Unsafe File Types
user_pref("network.jar.open-unsafe-types",			false);

// Don't reveal build ID
user_pref("general.buildID.override",				"20100101");

// Enable only whitelisted URL protocol handlers
user_pref("network.protocol-handler.warn-external-default",	true);
user_pref("network.protocol-handler.external.http",		false);
user_pref("network.protocol-handler.external.https",		false);
user_pref("network.protocol-handler.external.javascript",	false);
user_pref("network.protocol-handler.external.moz-extension",	false);
user_pref("network.protocol-handler.external.ftp",		false);
user_pref("network.protocol-handler.external.file",		false);
user_pref("network.protocol-handler.external.about",		false);
user_pref("network.protocol-handler.external.chrome",		false);
user_pref("network.protocol-handler.external.blob",		false);
user_pref("network.protocol-handler.external.data",		false);
user_pref("network.protocol-handler.expose-all",		false);
user_pref("network.protocol-handler.expose.http",		true);
user_pref("network.protocol-handler.expose.https",		true);
user_pref("network.protocol-handler.expose.javascript",		true);
user_pref("network.protocol-handler.expose.moz-extension",	true);
user_pref("network.protocol-handler.expose.ftp",		true);
user_pref("network.protocol-handler.expose.file",		true);
user_pref("network.protocol-handler.expose.about",		true);
user_pref("network.protocol-handler.expose.chrome",		true);
user_pref("network.protocol-handler.expose.blob",		true);
user_pref("network.protocol-handler.expose.data",		true);

// Ensure you have a security delay when installing add-ons (milliseconds)
user_pref("security.dialog_enable_delay",			1000);

// Opt-out of add-on metadata updates
user_pref("extensions.getAddons.cache.enabled",			false);

// Opt-out of themes (Persona) updates
user_pref("lightweightThemes.update.enabled",			false);

// Disable Flash Player NPAPI plugin
user_pref("plugin.state.flash",					0);

// Disable Java NPAPI plugin
user_pref("plugin.state.java",					0);

// Disable sending Flash Player crash reports
user_pref("dom.ipc.plugins.flash.subprocess.crashreporter.enabled",	false);

// When Flash crash reports are enabled, don't send the visited URL in the crash report
user_pref("dom.ipc.plugins.reportCrashURL",			false);

// When Flash is enabled, download and use Mozilla SWF URIs blocklist
user_pref("browser.safebrowsing.blockedURIs.enabled", true);

// Disable Shumway (Mozilla Flash renderer)
pref("shumway.disabled", true);

// Disable Gnome Shell Integration NPAPI plugin
user_pref("plugin.state.libgnome-shell-browser-plugin",		0);

// Updates addons automatically
user_pref("extensions.update.enabled",				true);

// Enable add-on and certificate blocklists (OneCRL) from Mozilla
user_pref("extensions.blocklist.enabled",			true);
user_pref("services.blocklist.update_enabled",			true);

// Decrease system information leakage to Mozilla blocklist update servers
user_pref("extensions.blocklist.url",				"https://blocklist.addons.mozilla.org/blocklist/3/%APP_ID%/%APP_VERSION%/");

// Disable WebIDE
user_pref("devtools.webide.enabled",				false);
user_pref("devtools.webide.autoinstallADBHelper",		false);
user_pref("devtools.webide.autoinstallFxdtAdapters",		false);

// Disable remote debugging
user_pref("devtools.debugger.remote-enabled",			false);
user_pref("devtools.chrome.enabled",				false);
user_pref("devtools.debugger.force-local",			true);

// Disable Mozilla telemetry/experiments
user_pref("toolkit.telemetry.enabled",				false);
user_pref("toolkit.telemetry.unified",				false);
user_pref("experiments.supported",				false);
user_pref("experiments.enabled",				false);
user_pref("experiments.manifest.uri",				"");

// Disallow Necko to do A/B testing
user_pref("network.allow-experiments",				false);

// Disable sending Firefox crash reports to Mozilla servers
user_pref("breakpad.reportURL",					"");

// Disable sending reports of tab crashes to Mozilla (about:tabcrashed), don't nag user about unsent crash reports
user_pref("browser.tabs.crashReporting.sendReport",		false);
user_pref("browser.crashReports.unsubmittedCheck.enabled",	false);

// Disable FlyWeb (discovery of LAN/proximity IoT devices that expose a Web interface)
user_pref("dom.flyweb.enabled",					false);

// Disable the UITour backend
user_pref("browser.uitour.enabled",				false);

// Enable Firefox Tracking Protection
user_pref("privacy.trackingprotection.enabled",			true);
user_pref("privacy.trackingprotection.pbmode.enabled",		true);

// Enable contextual identity Containers feature (Firefox >= 52)
user_pref("privacy.userContext.enabled",			true);

// Disable hardening against various fingerprinting vectors (Tor Uplift project)
// don't like it setting my timezone, so disabled for now
user_pref("privacy.resistFingerprinting",			false);

// Disable collection/sending of the health report (healthreport.sqlite*)
user_pref("datareporting.healthreport.uploadEnabled",		false);
user_pref("datareporting.healthreport.service.enabled",		false);
user_pref("datareporting.policy.dataSubmissionEnabled",		false);

// Disable Heartbeat  (Mozilla user rating telemetry)
user_pref("browser.selfsupport.url",				"");

// Disable Auto Update
user_pref("app.update.auto",					false);

// Enable blocking reported web forgeries
user_pref("browser.safebrowsing.enabled",			true); // Firefox < 50
user_pref("browser.safebrowsing.phishing.enabled",		true); // firefox >= 50

// Enable blocking reported attack sites
user_pref("browser.safebrowsing.malware.enabled",		true);

// Disable querying Google Application Reputation database for downloaded binary files
user_pref("browser.safebrowsing.downloads.remote.enabled",	false);

// Disable Pocket
user_pref("browser.pocket.enabled",				false);
user_pref("extensions.pocket.enabled",				false);

// Disable the predictive service (Necko)
user_pref("network.predictor.enabled",				false);

// Never check updates for search engines
user_pref("browser.search.update",				false);

// Disallow NTLMv1
user_pref("network.negotiate-auth.allow-insecure-ntlm-v1",	false);

// Enable CSP 1.1 script-nonce directive support
user_pref("security.csp.experimentalEnabled",			true);

// Enable Content Security Policy (CSP)
user_pref("security.csp.enable",				true);

// Enable Subresource Integrity
user_pref("security.sri.enable",				true);

// Send a referer header with the target URI as the source
// breaks cloudflare pages
user_pref("network.http.referer.spoofSource",			false);

// Spoof User-agent (disabled)
//user_pref("general.useragent.override",				"Mozilla/5.0 (Windows NT 6.1; rv:45.0) Gecko/20100101 Firefox/45.0");
//user_pref("general.appname.override",				"Netscape");
//user_pref("general.appversion.override",			"5.0 (Windows)");
//user_pref("general.platform.override",				"Win32");
//user_pref("general.oscpu.override",				"Windows NT 6.1");

// Disable password manager
user_pref("signon.rememberSignons",				false);

// Do not create screenshots of visited pages (relates to the "new tab page" feature)
user_pref("browser.pagethumbnails.capturing_disabled",		true);

// Enable insecure password warnings (login forms in non-HTTPS pages)
user_pref("security.insecure_password.ui.enabled",		true);

// Disable the "new tab page" feature and show a blank tab instead
user_pref("browser.newtabpage.enabled",				false);
user_pref("browser.newtab.url",					"about:blank");
user_pref("browser.newtabpage.activity-stream.enabled",				false);

// Disable new tab tile ads & preload
user_pref("browser.newtabpage.enhanced",			false);
user_pref("browser.newtab.preload",				false);
user_pref("browser.newtabpage.directory.ping",			"");
user_pref("browser.newtabpage.directory.source",		"data:text/plain,{}");

// Disable CSS :visited selectors
user_pref("layout.css.visited_links_enabled",			false);

// Do not check if Firefox is the default browser
user_pref("browser.shell.checkDefaultBrowser",			false);

// Enable HSTS preload list (pre-set HSTS sites list provided by Mozilla)
user_pref("network.stricttransportsecurity.preloadlist",	true);

// Enable Online Certificate Status Protocol
user_pref("security.OCSP.enabled",				1);

// Enable OCSP Stapling support
user_pref("security.ssl.enable_ocsp_stapling",			true);

// Enable OCSP Must-Staple support (Firefox >= 45)
user_pref("security.ssl.enable_ocsp_must_staple",		true);

// Require a valid OCSP response for OCSP enabled certificates
user_pref("security.OCSP.require",				true);

// Disable TLS Session Tickets
user_pref("security.ssl.disable_session_identifiers",		true);

// Only allow TLS 1.[0-3]
user_pref("security.tls.version.min",				1);
user_pref("security.tls.version.max",				4);

// Disable insecure TLS version fallback
user_pref("security.tls.version.fallback-limit",		3);

// Enfore Public Key Pinning
user_pref("security.cert_pinning.enforcement_level",		2);

// Disallow SHA-1
user_pref("security.pki.sha1_enforcement_level",		1);

// Warn the user when server doesn't support RFC 5746 ("safe" renegotiation)
user_pref("security.ssl.treat_unsafe_negotiation_as_broken",	true);

// Disable automatic reporting of TLS connection errors
user_pref("security.ssl.errorReporting.automatic",		false);

// Pre-populate the current URL but do not pre-fetch the certificate in the "Add Security Exception" dialog
user_pref("browser.ssl_override_behavior",			1);

// Ciphers
user_pref("security.ssl3.rsa_null_sha",				false);
user_pref("security.ssl3.rsa_null_md5",				false);
user_pref("security.ssl3.ecdhe_rsa_null_sha",			false);
user_pref("security.ssl3.ecdhe_ecdsa_null_sha",			false);
user_pref("security.ssl3.ecdh_rsa_null_sha",			false);
user_pref("security.ssl3.ecdh_ecdsa_null_sha",			false);
user_pref("security.ssl3.rsa_seed_sha",				false);
user_pref("security.ssl3.rsa_rc4_40_md5",			false);
user_pref("security.ssl3.rsa_rc2_40_md5",			false);
user_pref("security.ssl3.rsa_1024_rc4_56_sha",			false);
user_pref("security.ssl3.rsa_camellia_128_sha",			false);
user_pref("security.ssl3.ecdhe_rsa_aes_128_sha",		false);
user_pref("security.ssl3.ecdhe_ecdsa_aes_128_sha",		false);
user_pref("security.ssl3.ecdh_rsa_aes_128_sha",			false);
user_pref("security.ssl3.ecdh_ecdsa_aes_128_sha",		false);
user_pref("security.ssl3.dhe_rsa_camellia_128_sha",		false);
user_pref("security.ssl3.dhe_rsa_aes_128_sha",			false);
user_pref("security.ssl3.ecdh_ecdsa_rc4_128_sha",		false);
user_pref("security.ssl3.ecdh_rsa_rc4_128_sha",			false);
user_pref("security.ssl3.ecdhe_ecdsa_rc4_128_sha",		false);
user_pref("security.ssl3.ecdhe_rsa_rc4_128_sha",		false);
user_pref("security.ssl3.rsa_rc4_128_md5",			false);
user_pref("security.ssl3.rsa_rc4_128_sha",			false);
user_pref("security.tls.unrestricted_rc4_fallback",		false);
user_pref("security.ssl3.dhe_dss_des_ede3_sha",			false);
user_pref("security.ssl3.dhe_rsa_des_ede3_sha",			false);
user_pref("security.ssl3.ecdh_ecdsa_des_ede3_sha",		false);
user_pref("security.ssl3.ecdh_rsa_des_ede3_sha",		false);
user_pref("security.ssl3.ecdhe_ecdsa_des_ede3_sha",		false);
user_pref("security.ssl3.ecdhe_rsa_des_ede3_sha",		false);
user_pref("security.ssl3.rsa_des_ede3_sha",			false);
user_pref("security.ssl3.rsa_fips_des_ede3_sha",		false);
user_pref("security.ssl3.ecdh_rsa_aes_256_sha",			false);
user_pref("security.ssl3.ecdh_ecdsa_aes_256_sha",		false);
user_pref("security.ssl3.rsa_camellia_256_sha",			false);
user_pref("security.ssl3.ecdhe_rsa_aes_256_sha",		true); // 0xc014
user_pref("security.ssl3.ecdhe_ecdsa_aes_256_sha",		true); // 0xc00a
user_pref("security.ssl3.ecdhe_ecdsa_aes_128_gcm_sha256",	true); // 0xc02b
user_pref("security.ssl3.ecdhe_rsa_aes_128_gcm_sha256",		true); // 0xc02f
user_pref("security.ssl3.ecdhe_ecdsa_chacha20_poly1305_sha256",	true);
user_pref("security.ssl3.ecdhe_rsa_chacha20_poly1305_sha256",	true);
user_pref("security.ssl3.dhe_rsa_camellia_256_sha",		false);
user_pref("security.ssl3.dhe_rsa_aes_256_sha",			false);
user_pref("security.ssl3.dhe_dss_aes_128_sha",			false);
user_pref("security.ssl3.dhe_dss_aes_256_sha",			false);
user_pref("security.ssl3.dhe_dss_camellia_128_sha",		false);
user_pref("security.ssl3.dhe_dss_camellia_256_sha",		false);
user_pref("security.ssl3.rsa_aes_256_sha",			true); // 0x35
user_pref("security.ssl3.rsa_aes_128_sha",			true); // 0x2f