---
name: add-and-validate-guardian-developer-semgrep-rule
description: write a custom semgrep rule with the user, add it to guardian in either user or repo scope, and prove it fires by writing a file that should trip it. use when someone wants guardian to catch something it currently misses, asks to write or add a semgrep rule, or wants a project convention enforced on the code claude writes.
---

# write a semgrep rule and add it to guardian

guardian scans every file claude writes or edits. a custom rule makes it catch
something the deployment's ruleset does not — a project convention, a deprecated
internal api, a footgun this team keeps hitting.

rules live in two places, both read on every scan:

- `~/.semgrep/guardian-rules/` — **user scope**, follows the user into every repository
- `<repo root>/.semgrep/guardian-rules/` — **repo scope**, follows the code, so everyone who clones it gets the rule

add rules with `add_developer_semgrep_rule` rather than writing into those
directories by hand: it resolves the scope's directory and will not write over
a rule already there. it does not check the rule itself or count it against the
deployment's limit — that happens when a scan reads the rules, and step 5 is
how you find out.

**one rule per file.** guardian reads each file as a single rule. a file holding
two rules is rejected whole: neither is sent, and the scan runs as if the file
were not there.

## step 1 — check the feature is on

call `list_developer_semgrep_rules` before anything else. it reports both
directories, the rule files already there, whether they are being sent, and the
deployment's limit.

- "developer rules are not enabled for this deployment" — stop here. the
  scanner drops rules from a deployment without the flag, so a rule written now
  would never run. tell the user to ask their semgrep admin to enable
  `guardian.developer_rules_enabled`.
- "not logged into semgrep guardian" — have them log in (the `login` tool), then retry.

note the existing rule ids; yours has to be new.

## step 2 — get a concrete example

ask for code that **should** match, and if they have it, code that looks similar
and should not. you need the language, what makes the bad case bad as a code
shape rather than a feeling, and what nearby code must keep passing. write both
snippets down — step 5 uses them as fixtures.

## step 3 — write the rule

```yaml
rules:
  - id: no-direct-requests-get
    message: use the retrying client in lib/http.py, not requests.get directly.
    severity: WARNING 
    languages: [python]
    patterns:
      - pattern: requests.get(...)
      - pattern-not-inside: |
          def _retrying_get(...):
            ...
```

- `pattern` matches one shape. `...` stands for any sequence (arguments,
  statements, elements), and `$x` is a metavariable — the same name twice means
  the same code twice.
- `patterns:` is and, `pattern-either:` is or. cut false positives with
  `pattern-not`, `pattern-not-inside`, `metavariable-regex`.
- `languages:` takes `python`, `javascript`, `typescript`, `go`, `java`, `ruby`,
  `generic`, and the rest of semgrep's list. `severity:` is `ERROR`, `WARNING`, or `INFO`. 
- the `id` must be new and specific — `no-requests-get-in-handlers`, not `http`.
  against another local rule, the later file is dropped whole; against the
  deployment's ruleset, your rule is the one dropped.

two things about how guardian runs these, which should shape the rule:

- **a match blocks the write.** a noisy rule is not a warning, it is an edit the
  user has to argue with. prefer precise over broad.
- **a scan sees the files being written, one at a time.** patterns needing the
  rest of the repository — cross-file taint, a call graph — will not fire.

## step 4 — ask where it goes

use `askuserquestion`. the choice is who the rule is for:

- **repo** — a convention of *this codebase*. lands in
  `<repo>/.semgrep/guardian-rules/` and is shared with the team once committed.
- **user** — a habit of *this developer*, in every repository they open. lands in
  `~/.semgrep/guardian-rules/`, and nobody else sees it.

default to repo when the rule names anything specific to the project, user when
it is about how this person likes to write code.

## step 5 — add it, then make it fire

call `add_developer_semgrep_rule` with the rule text, the chosen `scope`, and a
`name` to write it as — name the file after the rule's id, e.g. `no-eval.yaml`.
the tool writes what you give it; it can only refuse the name or the place:

- `"x" must be a file name rather than a path` — pass a bare name.
- `<path> already exists; pass a different name` — that file is somebody's
  working rule. pick another name, or edit that file if the user meant to
  replace it.
- `repo scope needs a git repository, and this is not one` — offer user scope.

the add succeeding says nothing about whether the rule is usable or fits: the
tool writes the file first and checks nothing. so call
`list_developer_semgrep_rules` straight away, before any other write, and find
the new file in it:

- the file carries an error — guardian could not use it: yaml that does not
  parse, a rule with no `id`, more than one rule in the file. it is left out of
  every scan without a word, so fix it in place now; the fixture below would
  just go through.
- `n developer rules on disk, over the limit of m` — the deployment's cap, and
  your file is what crossed it. going over does not mean the extra rule is
  ignored: *no* rules are sent, and guardian blocks writes until the count is
  back under. delete the file you just added, at the path the add returned,
  and list again to confirm rules are being sent. then tell the user: to keep
  this rule, retire another (the `remove-guardian-developer-semgrep-rule`
  skill) and add it again.
- `developer rules are n bytes, over the m byte limit` — the same thing by
  weight rather than by count, and it blocks the same way. delete the new file
  as above, then offer to shrink the rule (a shorter `message`, less
  `metadata`, fewer `pattern-not` clauses) and add it again, or retire another.

do not write the fixture until the listing shows every rule being sent and your
file among them without an error.

guardian checks only the shape, not whether semgrep will accept the rule. a rule
the scanner rejects shows up in the next step as a *failed* scan carrying the
scanner's parse error rather than as a block. that is the signal to fix the yaml
and try again.

now test it the way it will actually be used, by writing code that trips it.
tell the user first that the write is *meant* to be blocked, so the block does
not read as a failure.

1. write the matching snippet to a new file in the working directory — say
   `guardian-rule-check.py`. use **write** on a **new** file: an edit only reports
   findings the edit introduced, and a new file has no baseline to subtract.
   give it a real source extension; markdown is never scanned, and files outside
   the working directory are not either.
2. guardian scans it on the way out and blocks with the rule's `message`. that
   block is the rule working. a scan that *fails* instead means the scanner
   would not take the rule — read its error, fix the file in place, and write
   the fixture again.
3. write the near-miss snippet to a second file and confirm it goes through
   untouched. a rule that blocks both is too broad.
4. delete both files.

if nothing fires, the rule is already on disk — edit it in place in the scope's
directory and write the fixture again; every scan re-reads the rules, so nothing
needs restarting. work through, in order: does `list_developer_semgrep_rules`
say the rules are being sent, does `languages:` match the fixture's extension,
and is the pattern too specific (drop the `pattern-not` clauses and narrow again
from a rule that fires).

## step 6 — confirm

run `list_developer_semgrep_rules` once more and tell the user:

- the path the rule landed at, and its scope
- that the fixtures are deleted
- for repo scope, to commit the file
- that these are plain yaml files in those two directories — edit or delete them
  directly, no tool needed

## notes

- a rule file may hold a top-level `rules:` list with one entry or a single bare
  rule. either works; a second rule in the same file, or a second yaml document
  after `---`, makes the whole file unusable.
- the deployment caps how many rules a scan carries, because they ride along on
  every scan. `list_developer_semgrep_rules` reports the cap and how many of the rules on
  disk fit under it.
- the rule text goes to the semgrep scanner with the scan and nowhere else. keep
  secrets out of a rule's `message` and `metadata` all the same.
