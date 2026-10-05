#!/usr/bin/env bash
# Shared logic for the Claude review machinery. Used by claude-review.yml (from
# the pull request's merge ref, integrity-checked) and by claude-review-gate.yml
# (from the default branch). One copy, so the two can never drift apart.
#
#   lib.sh checks  REPO SHA           -> pass | pending | missing: … | failed: …
#   lib.sh verdict REPO PR SHA REF    -> {"verdict","run","full","replies"} JSON
#
# This file is review machinery: the gate's integrity check covers it, and the
# push ruleset that restricts .github/workflows/** must restrict it too.
set -euo pipefail

REQUIRED_WORKFLOW=".github/workflows/ci.yml"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Did every other check on this commit pass? Latest run per workflow file.
# "No runs" is NOT "passed": the CI workflow itself must have run and succeeded
# on this exact commit. A [skip ci] head, or one whose CI run was deleted, is
# `missing`, never `pass`.
checks() {
  local repo=$1 sha=$2 runs failed
  runs=$(gh api "repos/$repo/actions/runs?head_sha=$sha&per_page=100" --paginate \
    | jq -s '[.[].workflow_runs[]
              | select(.path | test("^\\.github/workflows/claude-") | not)
              | {path, name, status, conclusion, id}]
             | group_by(.path) | map(max_by(.id))')
  failed=$(jq -r '[.[] | select(.status == "completed"
                              and (.conclusion | IN("success", "skipped", "neutral") | not))
                   | "\(.name) (\(.conclusion))"] | join(", ")' <<<"$runs")
  if [ -n "$failed" ]; then echo "failed: $failed"; return; fi
  if jq -e 'any(.[]; .status != "completed")' <<<"$runs" >/dev/null; then echo "pending"; return; fi
  if ! jq -e --arg p "$REQUIRED_WORKFLOW" 'any(.[]; .path == $p and .conclusion == "success")' <<<"$runs" >/dev/null; then
    echo "missing: $REQUIRED_WORKFLOW has not run on this commit"; return
  fi
  echo "pass"
}

# The verdict for one pull request at one head commit and base branch.
#
# Which runs count:
#   - runs recorded against this head commit (push, label and inline-reply
#     reviews -- an inline-reply run is recorded against the PR head), and
#   - `issue_comment` runs on the default branch: those execute the
#     default-branch copy of the workflow and are recorded against its commit.
# Never comment-triggered runs repo-wide: those can execute another pull
# request's merge-ref copy of the workflow, whose step names it controls.
#
# How they combine, in order of when each VERDICT was reached (not when the run
# was created):
#   - push/label: a failure is sticky -- re-running cannot launder it.
#   - reply: overrides only if a full push/label verdict already existed AND the
#     reply review started after the latest full verdict was reached -- so it
#     saw every finding it is overriding, and a reply alone never stands in for
#     a full review.
verdict() {
  local repo=$1 pr=$2 sha=$3 ref=$4 default since rid attempts k resp
  default=$(gh api "repos/$repo" --jq '.default_branch')
  since=$(gh api "repos/$repo/commits/$sha" --jq '.commit.committer.date')
  { gh api "repos/$repo/actions/workflows/claude-review.yml/runs?head_sha=$sha&per_page=100" --paginate \
      --jq '.workflow_runs[] | "\(.id) \(.run_attempt // 1)"'
    gh api "repos/$repo/actions/workflows/claude-review.yml/runs?event=issue_comment&branch=$default&created=%3E%3D$since&per_page=100" --paginate \
      --jq '.workflow_runs[] | "\(.id) \(.run_attempt // 1)"'
  } | sort -n -u > "$TMP/runs"

  : > "$TMP/recs"
  while read -r rid attempts; do
    [ -n "$rid" ] || continue
    for k in $(seq 1 "${attempts:-1}"); do
      if ! resp=$(gh api "repos/$repo/actions/runs/$rid/attempts/$k/jobs" 2>/dev/null); then
        echo "lib.sh: could not read attempt $k of run $rid" >&2
        return 1
      fi
      jq -c --arg want "context pr=$pr head=$sha ref=$ref " --argjson rid "$rid" '
        .jobs[]
        | select(any(.steps[]?; .name | startswith($want)))
        | ([.steps[] | select(.name == "Verdict: no blocking findings")][0] // {}) as $v
        | select($v.conclusion == "success" or $v.conclusion == "failure")
        | { rid: $rid,
            trigger: ([.steps[] | select(.name | startswith("context ")) | .name
                       | (capture("trigger=(?<t>[a-z]+)").t // "push")] | first // "push"),
            started: .started_at,
            result: $v.conclusion,
            done: $v.completed_at }' <<<"$resp" >> "$TMP/recs"
    done
  done < "$TMP/runs"

  jq -s 'sort_by(.done)
    | reduce .[] as $r ({verdict: "none", run: null, full: false, last_full: "", replies: 0};
        if $r.trigger == "reply" then
          .replies += 1
          | if .full and ($r.started > .last_full) then .verdict = $r.result | .run = $r.rid else . end
        else
          .full = true | .last_full = $r.done
          | if $r.result == "failure" then .verdict = "failure" | .run = $r.rid
            elif .verdict != "failure" then .verdict = "success" | .run = $r.rid
            else . end
        end)
    | del(.last_full)' "$TMP/recs"
}

cmd=${1:?usage: lib.sh checks|verdict ...}; shift
case "$cmd" in
  checks) checks "$@" ;;
  verdict) verdict "$@" ;;
  *) echo "lib.sh: unknown command $cmd" >&2; exit 2 ;;
esac
