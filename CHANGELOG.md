# Changelog

## Unreleased
- Guardian now reports its status at session start, and says so when it is not configured
- The session-start check verifies your credentials again, so an expired token is reported
  immediately instead of at the first blocked edit. It is capped at 1.5s for the check and
  2s for the hook, and says the check timed out rather than making you wait
- Added a Stop-hook summary reporting scans, files and findings at the end of every turn
- The end-of-turn summary no longer waits on the network: it reads from disk, so an
  unreachable Semgrep costs a fraction of a second per turn instead of tens of seconds
- Session start no longer opens a browser when the problem is the network rather than
  your credentials, and no longer loses a refreshed token when it checks them
- A scan that fails is counted and named at the end of the turn, instead of looking exactly like a clean one
- The end-of-turn summary counts only scans that reached the scanner, so an unchanged file is no longer reported as scanned
- Files Guardian declines to scan are named on the Stop summary, with the reason
- Guardian says when it is signing you in, and says at the end of a turn when it never got signed in
- An unfinished login now says it was never finished, instead of failing with no explanation
- Users who belong to no deployment, or to several with the scan deployment picked for them rather than by them, are asked to log in again
- A credential the service refuses, or one that can't settle a deployment, is now cleared on the way into the login that replaces it
- Clearing that credential no longer lets a Semgrep CLI api token quietly take its place: until a login completes, Guardian stays signed out rather than scanning under whichever deployment that token belongs to
- Fixed a crash when guardian.yml holds a refresh token but no oauth client or metadata
- Fixed a crash when auth was checked before settings had loaded

## 2.0.1
- Splash Screen improved
- Better reporting around rate limiting
- Removed prompt defaults

## 2.0.0

- First public release
