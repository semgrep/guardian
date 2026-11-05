---
name: recommend-guardian-policy-rules
description: Recommend Semgrep rules to add to the organization's Guardian policy for a repository — pull the rules Guardian runs now, gather candidates from the repo's existing findings and the org's custom rules, rank them for Guardian, let the user pick, and turn the picks on through the Semgrep MCP. Use when someone wants Guardian to catch more, asks which rules Guardian should run, or wants to tune or customize the Guardian policy for a repo.
---

# Recommend rules for the Guardian policy

Guardian's policy is the set of Semgrep rules every scan runs. Most
organizations run the `guardian-default` set and nothing else, so Guardian
misses what their CI scans already know the code gets wrong. This skill closes
that gap for one repository, using rules with a track record in it:

1. read what Guardian runs now
2. gather candidate rules from what Semgrep has already found in the repo
3. drop the ones Guardian already runs, and rank the rest for how well they suit Guardian
4. let the user pick, then turn the picks on

Every call goes through the Semgrep MCP tools Guardian forwards from Semgrep's
hosted server, so they act as the user who logged in to Guardian, with that
user's permissions.

**The policy covers the whole organization.** Guardian has no per-repository
scoping yet. A rule picked "for" this repo also runs on every write in every
other repo in the org. Say that before anything gets written.

## Step 1 — Check the tools are there

You need these hosted tools. MCP tools can be deferred, so search for any that
are not in your list before deciding they are missing:

- `semgrep_account`
- `RuleScopeService_GetResolvedSurfaceRuleIds`, `RuleScopeService_SetRuleSurfaceScopes`
- `IssuesService_ListIssues`
- `Registry_get_registry_rule`, `Registry_get_organization_rules`

If none of them exist, call `status`. The hosted server lists them only for an
org with MCP access, and only once Guardian is logged in. Pass on what `status`
says, then stop.

Call `semgrep_account`. Each org's `id` is its **deploymentId**, used by every
call below. If it lists more than one org, ask which one.

## Step 2 — Read what Guardian runs now

Call `RuleScopeService_GetResolvedSurfaceRuleIds`:

```
path:  { deploymentId: "<id>" }
query: { surface: "SCAN_SURFACE_GUARDIAN", ruleProductType: "PRE_SCAN_CONFIG_TYPE_SAST" }
```

- `ruleIds` holds the rules Guardian runs now: the default set plus this org's changes.
- `defaultRuleIds` holds the default set alone. Rules in `ruleIds` but not here were added by the org.
  Rules here but not in `ruleIds` were turned off.

Both lists hold rule **hashids** (short strings like `gxU149`), not registry
paths. Keep `ruleIds` as a set; step 4 drops candidates that are already in it.
Tell the user how many rules Guardian runs, and how many of those the org added
itself.

A permission error here means the user is not an admin of the org. Changing the
policy needs the same permission, so stop and say so.

## Step 3 — Gather candidates

Pick the repository. Default to the one you are working in: take its name from
`git remote get-url origin`, in `owner/repo` form. Confirm it with the user if
there is any doubt.

### From the repo's findings (the main source)

A rule that has already found real problems in this repo is the best candidate
there is. Call `IssuesService_ListIssues` twice, both with:

```
path:  { deploymentId: "<id>" }
query: { fieldMask: "issues.issue.rulePath,issues.issue.severity,issues.issue.confidence" }
body:  {
  issueTypes: ["ISSUE_TYPE_SAST"],
  limit: 100,
  filter: { repositoryNames: ["<owner/repo>"], relativeSince: "RELATIVE_SINCE_ONE_YEAR", ... }
}
```

1. **True positives**: add `aggregateIssueStates: ["AGGREGATE_ISSUE_STATE_OPEN",
   "AGGREGATE_ISSUE_STATE_FIXING", "AGGREGATE_ISSUE_STATE_FIXED"]` to the
   filter. Fixed issues count too: the bug was real, and Guardian would have
   stopped it before it landed.
2. **False positives**: add `aggregateIssueStates: ["AGGREGATE_ISSUE_STATE_IGNORED_APP"]`
   and `triageReasons: ["FINDING_TRIAGE_REASON_FALSE_POSITIVE"]` to the filter.

Follow `cursor` on each until it runs out or you have seen about 1,000 issues,
which is enough to rank by. Count each `rulePath` in both.

If the repo has no issues, say so. Then offer to look across the org instead:
drop `repositoryNames`, or filter by `repositoryTags` or `teamNames`.

### From the org's own rules

Custom rules that have fired in the repo are already among the findings above,
with origin `custom`. To find custom rules that have not fired yet, call
`Registry_get_organization_rules` with `path: { deployment_id: "<id>" }` and
`query: { fieldMask: "rules.path,rules.rule_type,rules.meta.rule.rule_id" }`.
Always pass the mask: a large org has thousands of rules, and the list is
long even without their definitions. If it comes back with more than about 200
rules, do not rank them all. Keep only paths whose names point at the repo's
languages or frameworks, or skip this source and say so. Rank custom rules with
no findings below rules that have found something.

### More, only if the user asks

If the user names a ruleset or technology, list its rules with
`Registry_list_registry_rules`, passing `starts_with` (for example `python.django.`)
and `deployment_id`. Rules with no findings behind them are guesses. Rank them
below the rest, and say why each was picked.

## Step 4 — Resolve, filter and rank

Look up each candidate path with `Registry_get_registry_rule`:

```
path:  { hashid_or_path: "<rulePath>" }
query: { deployment_id: "<id>",
         fieldMask: "path,rule_type,meta.rule.rule_id,meta.rule.origin,definition.rules.severity,definition.rules.languages,definition.rules.mode,definition.rules.options,definition.rules.metadata.confidence,definition.rules.metadata.subcategory" }
```

`meta.rule.rule_id` is the hashid that the policy calls take. `meta.rule.origin`
is `community`, `pro_rules`, or `custom`. Org rules need the `deployment_id` to
resolve. Look up the top 30 or so by true-positive count, not every path you saw.

Drop a candidate when:

- its hashid is already in step 2's `ruleIds`. Guardian already runs it.
- `rule_type` is not `sast`. Guardian's code policy takes only code rules.
- false positives are at least as many as true positives. **Every match blocks
  the write**, so a noisy rule makes edits the user has to argue with.
- none of its `languages` appear in the repo. `generic` and `regex` count as matching everything.

Rank what is left, best first:

1. more true positives in this repo
2. `metadata.confidence` `HIGH`, then `MEDIUM`. Rank `LOW` and audit rules
   (`subcategory: [audit]`) last.
3. severity `CRITICAL`/`ERROR` and `HIGH`, then `WARNING`/`MEDIUM`

Two more things to note against a rule, without dropping it:

- **`options.interfile: true`**: Guardian scans one written file at a time, so
  the rule fires only when source and sink are in the same file.
- **it adds to every scan**: each rule rides along on every Guardian scan, and
  scans run under tight latency and size limits. Recommend about 10 rules, and
  never more than 25 in one go.

## Step 5 — Let the user pick

Show the ranked list as a table:

| # | rule path | origin | lang | sev / conf | TP | FP | note |
|---|-----------|--------|------|------------|----|----|------|

Keep the hashid of each row to yourself; the user picks by number or path.
Under the table, say again that whatever they pick runs across the whole org.

Ask which to add: "all", a list of numbers, or none. `AskUserQuestion` takes at
most four options, so use it only when there are four or fewer candidates. For
a longer list, ask in plain text and wait for the reply.

## Step 6 — Turn them on

Before writing, repeat the exact rules that will be added and the org they go
to, and get a yes. The change shows up in the org's audit log under the user's name.

Call `RuleScopeService_SetRuleSurfaceScopes`, with at most 100 rules per call:

```
path: { deploymentId: "<id>" }
body: {
  surface: "SCAN_SURFACE_GUARDIAN",
  ruleProductType: "PRE_SCAN_CONFIG_TYPE_SAST",
  rules: [ { ruleId: "<hashid>", enabled: true }, ... ]
}
```

Send **only the rules being changed**. The call touches exactly the rules it is
given, and leaves every other rule in the policy alone. Never send all of
`ruleIds` back.

The response's `ruleIds` is the full set Guardian runs afterwards. Check that every hashid you
sent is in it. An error naming a rule (wrong product type, bad hashid) leaves
the whole batch unapplied: drop that rule and send the rest again.

## Step 7 — Confirm, and prove one fires

Tell the user:

- which rules were added, by path, and the new total Guardian runs
- that they apply to Guardian's next scan, in every repo in the org, with nothing to restart
- how to undo: run this skill's step 6 with `enabled: false` for the same hashids.
  For a rule outside the default set, that removes it again; for a default rule, it turns the rule off.

Offer to prove one fires. Pick a rule with a true positive in this repo. Tell
the user the write is *meant* to be blocked. Then write a small **new** file
with a real source extension in the working directory that reproduces the
pattern. Guardian should block it with the rule's message. Delete the file afterwards.

## Notes

- To turn rules **off**, follow the same steps with `enabled: false`, choosing
  candidates from `ruleIds`. Good reasons to turn one off are rules that mostly
  produce false positives here, or rules for languages the org does not use.
- `RuleScopeService_ListRuleSurfaceScopes` lists the org's stored changes. They
  can differ from what Guardian runs, because default rules and packs are worked out
  separately, so treat `GetResolvedSurfaceRuleIds` as the source of truth.
- This changes the **organization's** policy on Semgrep. A rule for one
  developer or one repository alone is a local developer rule instead: see the
  `add-and-validate-guardian-developer-semgrep-rule` skill.
