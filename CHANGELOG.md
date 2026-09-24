# Changelog

## 2.4.0
- Shell commands are now scanned from the files Claude Code reports they changed (Claude Code 2.1.269
  or newer), so `sed -i`, `python3 -c` and installs in subdirectories are covered; without that report
  (older Claude Code, the feature off, outside a git repository) Guardian reads the command
- Supply-chain scans now follow the lockfile a shell command actually changed, so an install
  in a nested package is scanned, and an install no longer spends the SAST scan on the lockfile
- Fixed the build replacing plugin binaries in place, which left macOS killing every hook
  with SIGKILL and no output after a rebuild
- Every scan now carries `client_metrics`, starting with the signed-in user's email, so users
  sharing an app token can be told apart: an OAuth login's own address, or for an app token,
  `SEMGREP_GUARDIAN_EMAIL` (for instance from an MDM template). Telemetry carries only its
  SHA-256, never the address
- Added support for developer rules (i.e. local rules in repo and user scope) under a feature flag

## 2.3.0
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
- Guardian now reports per-session metrics: sessions, files scanned, new findings, how long the session ran and how much of that was Guardian's own time, tool calls it blocked, scans that failed, edits attempted while signed out, waits on rate limiting and on scanner capacity, and files too large to scan - tagged by deployment, which client it ran in, how the session ended, whether Guardian was active, and how it started
- The end-of-turn summary and those metrics now come from one tally per hook process, so an edit is counted once and a shell command that writes a file is one scan rather than two
- The stale-session sweep and the end-of-turn tally stop at the hook's deadline instead of running past it, and a tally that cannot finish in time says nothing rather than reporting a number that is short

## 2.0.1
- Splash Screen improved
- Better reporting around rate limiting
- Removed prompt defaults

## 2.0.0

- First public release
