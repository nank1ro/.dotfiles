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
// Normalise host: strip any :port and lowercase (robust regardless of Finicky's host/port split).
const host = (url) => url.host.split(":")[0].toLowerCase();

export default {
  // Unmatched links: launch Helium with no profile flag => its last-used profile.
  defaultBrowser: HELIUM,
  handlers: [
    // 1) qurami org on github => ufirst  (MUST come before the github->work rule)
    {
      match: ({ url }) => {
        if (host(url) !== "github.com") return false;
        const p = url.pathname;
        return p === "/qurami" || p.startsWith("/qurami/") ||
               p === "/orgs/qurami" || p.startsWith("/orgs/qurami/");
      },
      browser: helium(UFIRST),
    },
    // 2) all other github.com (+ subdomains: gist., api., …) => work
    {
      match: ({ url }) => { const h = host(url); return h === "github.com" || h.endsWith(".github.com"); },
      browser: helium(WORK),
    },
    // 3) Google Meet => ufirst
    { match: ({ url }) => host(url) === "meet.google.com", browser: helium(UFIRST) },
    // 4) local development => work
    {
      match: ({ url }) => {
        const h = host(url);
        return h === "localhost" || h.endsWith(".localhost") ||
               h === "127.0.0.1" || h === "0.0.0.0" ||
               h.endsWith(".test") || h.endsWith(".local");
      },
      browser: helium(WORK),
    },
  ],
};
