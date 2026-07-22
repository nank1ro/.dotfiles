// Helium "Air Traffic Control": route links opened from OTHER apps into the right profile.
// (Links clicked inside Helium are not affected — Finicky never sees them.)
//
// profile = Chromium profile DIRECTORY name, not the display name:
//   work -> "Default", ufirst -> "Profile 1", private -> "Profile 2"
// "qurami" is ufirst's former registered company name; its GitHub org routes to ufirst.
const HELIUM = "Helium";
const WORK = "Default";
const UFIRST = "Profile 1";

const helium = (profile) => ({ name: HELIUM, profile });

// Bare hostname: lowercase, strip a trailing :port (IPv6-safe: only a numeric port at the
// end), and drop a trailing FQDN dot. Guards against a missing host on odd schemes.
const host = (url) => (url.host || "").toLowerCase().replace(/:\d+$/, "").replace(/\.$/, "");
const isGithub = (h) => h === "github.com" || h.endsWith(".github.com");

export default {
  // Unmatched links: launch Helium with no profile flag => its last-used profile.
  defaultBrowser: HELIUM,
  handlers: [
    // 1) qurami org on github => ufirst  (MUST come before the github->work rule)
    {
      match: ({ url }) => {
        if (!isGithub(host(url))) return false;
        const p = url.pathname.toLowerCase(); // GitHub org/repo paths are case-insensitive
        return p === "/qurami" || p.startsWith("/qurami/") ||
               p === "/orgs/qurami" || p.startsWith("/orgs/qurami/");
      },
      browser: helium(UFIRST),
    },
    // 2) all other github.com (+ subdomains: gist., api., www.) => work
    {
      match: ({ url }) => isGithub(host(url)),
      browser: helium(WORK),
    },
    // 3) Google Meet => ufirst
    { match: ({ url }) => host(url) === "meet.google.com", browser: helium(UFIRST) },
    // 4) local development => work
    {
      match: ({ url }) => {
        const h = host(url);
        return h === "localhost" || h.endsWith(".localhost") ||
               h === "127.0.0.1" || h === "0.0.0.0" || h === "::1" || h === "[::1]" ||
               h.endsWith(".test") || h.endsWith(".local");
      },
      browser: helium(WORK),
    },
  ],
};
