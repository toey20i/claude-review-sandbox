# Review instructions

Standing rules for automated review of this repository. Read alongside
[`CLAUDE.md`](./CLAUDE.md).

## What to review for

Correctness and regressions first. Then, in rough order of how much they have
cost this repository: data loss, migration safety, concurrency and races,
privacy leaks, authorization and authentication, API contract changes, and
missing tests.

## Evidence and confidence

- **Cite `file:line` for every behavioral claim.** A finding that cannot point
  at the line it is about is not a finding.
- **Verify against the surrounding implementation, not the diff alone.** Most
  real defects here were invisible in the diff and only appeared when the
  changed line was read against its caller, its transaction boundary, or the
  module-init order around it.
- **Prefer a few high-confidence findings to a long speculative list.** Five
  solid findings beat twenty that need triage.
- **Do not invent problems to have something to say.** "No blocking issues" is
  a valid and useful review.
- **Separate defects from nits.** Lead with what blocks; group style and naming
  separately and keep it short.

## Failure and error paths

Look for the paths nobody tested. Empty `catch` blocks, swallowed errors,
and error handlers whose recovery is more destructive than the error are worth
flagging even when the happy path is correct.

## Test integrity

- **Flag tests that reimplement production logic instead of importing it.** A
  spec that hand-copies the function it claims to cover passes when the
  production code is deleted. If a changed source file is not imported —
  directly or transitively — by any spec that claims to cover it, say so.
- Flag a test that would still pass with the production change reverted.
- Flag a test that fails for the wrong reason: a missing-module or
  wrong-type error is not evidence that the behavior is pinned.
- Flag new logic with no test, and deleted tests with no stated justification.

## Reporting

- **The review is one top-level body plus optional inline comments.** Write the
  body as a reviewer on this team would: a `## Approving — …` or
  `## Requesting changes — …` heading, what you verified with `file:line`, the
  blocking asks, then non-blocking notes marked as such. Inline comments are for
  findings that belong on a specific line.
- **Start every inline comment with `[blocking]` or `[non-blocking]`.** The
  workflow requests changes if the structured `decision` is `request_changes` or
  any inline comment is `[blocking]` (or untagged), and approves otherwise. `[blocking]` means the pull
  request must not merge until it is fixed: a correctness bug or regression,
  data loss, an unsafe migration, a race, a security, authorization or PHI
  problem, a broken API contract, a test that does not test what it claims, or a
  violation of a MUST rule in `CLAUDE.md` or this file. Style, naming,
  readability and optional refactors are `[non-blocking]`.
- Open the summary with a one-line tally, e.g. `3 blocking, 2 nits`.
- Lead with "No blocking issues" when that is the case, before any detail.
- Cap nits at five per review; mention the rest as a count.
- Do not report anything CI already enforces: formatting, lint, type errors,
  or the checks in `scripts/checks/`.
- On a re-review, suppress nits already raised and report only new or
  still-unresolved blocking findings.
