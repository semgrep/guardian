---
name: reconnect
description: Re-check Semgrep Guardian's connection and recover it — verify the credential live, and log in again if it is expired. Use when Guardian reported that it timed out checking credentials or could not reach Semgrep, when scans seem not to be running, or when the user asks to reconnect Guardian.
---

# Reconnect Guardian

Guardian's startup check gives up after a couple of seconds, so a slow network can
leave a session saying it could not confirm the credential when the credential is
fine. This skill re-runs that check without the time limit and fixes what it can.

## Step 1 — Check

Call `status`. It re-verifies the credential live and returns a `state`, a
`summary` and, when there is something to do, an `action`.

If `status` is not in your tool list, search for it first: MCP tools can be
deferred. Only if the search finds nothing is the Guardian MCP server not
running. Then tell the user to run `/mcp reconnect plugin:semgrep:guardian` in Claude Code
(confirm the name in `/mcp`), or to restart the Guardian MCP server in other clients, then try
again. Do not retry in a loop.

## Step 2 — Act on the state

- `ok` — nothing to fix. Tell the user Guardian is connected and scanning.
- `not_logged_in` or `login_required` — call `login`. A browser tab opens for the
  user to sign in; say so, and that scanning starts once they finish. If `login`
  says one is already in progress, ask them to finish the open browser tab, then
  check again. If the `summary` says `SEMGREP_APP_TOKEN` cannot be used, `login` is still
  the fix: call it once to sign in interactively. If the state does not change, relay the
  `summary` rather than calling `login` again.
- `unconfirmed` or `unreachable` — Semgrep could not be reached. Scanning is still
  attempted, and the credential on disk is usually fine. Offer one more `status`
  call after the user checks their network or VPN; do not log in again, which
  would replace a working credential.
- `blocked` — a login will not help. Relay the `summary` and `action`: it is an
  organization access, plan or sign-in policy matter for their Semgrep admin, or,
  when it names `SEMGREP_GUARDIAN_TOKEN_COMMAND`, to fix wherever that command gets
  its token.

## Step 3 — Confirm

After a login, call `status` once more and report the new `state`. Keep the
report to a sentence or two; do not print tokens or settings files.
