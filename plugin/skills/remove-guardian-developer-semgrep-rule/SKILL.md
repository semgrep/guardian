---
name: remove-guardian-developer-semgrep-rule
description: Remove a custom Semgrep rule from Guardian — list what is installed, work out which file holds the rule, and delete or edit it out of the user or repo rules directory. Use when someone wants Guardian to stop flagging something, asks to remove, delete or disable a custom rule, or wants to clear room under the rule limit.
---

# Remove a custom Semgrep rule

Custom rules are plain files in two directories, both read on every scan:

- `~/.semgrep/guardian-rules/` — **user scope**, this developer everywhere
- `<repo root>/.semgrep/guardian-rules/` — **repo scope**, everyone who clones the repository

There is no removal tool, because there is nothing to undo in a service: taking
a rule off disk is the whole of it. What matters is removing the *right* one, and
knowing who else loses it.

## Step 1 — List what is there

Call `list_developer_semgrep_rules`. It reports both directories, every rule file
with its scope and path, whether the rules are being sent, and the deployment's
limit. A file holds one rule or several, so check what a file carries before
removing it: the count drops by every rule in it.

If it refuses because the feature is off for the deployment, the rules on disk
are still just files — nothing is being sent, so removal is still fine. List the
two directories yourself and carry on.

## Step 2 — Find the rule they mean

The user will usually name a finding, not a file. Match what they describe — a
rule id, a message they keep seeing, a path — against the listing. If more than
one fits, ask with `AskUserQuestion`, showing the id, the scope and the path for
each; do not guess between two plausible rules.

Three cases worth noticing in the listing:

- It says no rules are being sent because the directories hold more than the
  deployment's limit. Then removing one is not tidying, it is the fix: every
  rule is currently doing nothing, and Guardian blocks the writes it would have
  scanned until the count is back under.
- A file reported with an error is not being sent at all — too big, unreadable,
  or not a usable rule. Removing it changes nothing about what is scanned, but
  read the error first: a file that fails to parse takes every rule in it down,
  and the user may want the others kept.
- Every write is being blocked with *a developer rule is not valid*. The
  scanner validates the rules it is sent before running anything, and one that
  fails takes the whole scan down with it, so no scan runs until that rule is
  fixed or gone. Semgrep's own message in the block names what is wrong; fixing
  the file is usually better than deleting it, so offer that first.

## Step 3 — Confirm what goes, and who loses it

Before touching anything, tell the user the path, the rule id, and — for repo
scope — that the rule is shared, so removing it takes it away from everyone who
clones the repository. Get a yes for a repo-scope removal.

## Step 4 — Remove it

- **The file holds only that rule** — delete the file.
- **The file holds several** — it is already rejected, so none of them run.
  Move each rule the user wants to keep into a file of its own in the same
  directory, named after its id, then delete the original. Check the listing
  afterwards: each new file should be usable and counted.

Only ever touch files inside the two rules directories, and only the file you
named in step 3. Never delete a directory.

If the user wants the rule *off for now* rather than gone, do not delete it:
rename it to an extension that is not read — `no-eval.yaml.off` — or move it into
a subdirectory of the rules directory. Only `.yaml`, `.yml` and `.json` files
directly in the directory are loaded, so either way the rule stops running and
the text is still there to restore.

## Step 5 — Confirm

Run `list_developer_semgrep_rules` again and tell the user:

- that the rule is gone, and from which scope
- that it stops applying on the next write or edit Claude makes — nothing to restart
- for repo scope, to commit the deletion
- if the count was the problem: that rules are being sent again, and scans with
  them
