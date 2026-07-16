---
description: Read-only cross-artifact consistency check — gaps, violations, drift
handoffs:
  - label: Implement
    agent: amonite.implement
    prompt: "Analysis complete — proceed with implementation"
    send: false
  - label: Re-plan gaps
    agent: amonite.plan
    prompt: "Gaps found in analysis — update the plan to cover them"
    send: false
---

# Analyze Artifact Consistency

Read `.amonite/{principles,spec,plan,tasks}.md` and produce a severity-graded findings
table. **STRICTLY READ-ONLY** — this command writes nothing. Its output is a report to
the conversation only.

## When to run

After `/amonite.tasks` and before `/amonite.implement`. Also useful after
`/amonite.converge` to confirm gaps were closed. Safe to re-run at any time.

## Steps

1. **Read all four artifacts**:
   - `.amonite/principles.md` — the project constitution
   - `.amonite/spec.md` — user stories and "Done when" bullets
   - `.amonite/plan.md` — architecture, cluster topology, task decomposition
   - `.amonite/tasks.md` — task list with verify criteria

2. **Build coverage maps**:
   - Requirements map: `{ USN → [TNNN, ...] }` — which tasks cover each user story
   - Tasks map: `{ TNNN → [USN, ...] }` — which stories each task claims to address

3. **Check for findings** at each severity level:

   | Severity | What to look for |
   |----------|-----------------|
   | CRITICAL | Verify criterion that would pass even if the story's intent is unmet (hollow check) |
   | CRITICAL | Plan or task directly contradicts `.amonite/principles.md` |
   | HIGH     | User story has no task with its `[USN]` label in tasks.md |
   | HIGH     | "Done when" bullet has no corresponding `verify` entry in any task |
   | MEDIUM   | Task has no `[USN]` label — orphaned, no traceability to a requirement |
   | MEDIUM   | Key term used differently across spec/plan/tasks (terminology drift) |
   | LOW      | Task verify uses only `test -f` or bare `grep -q` with no behavioral follow-up |
   | LOW      | Plan mentions a component not referenced in any task |

4. **Produce the findings report**:

   ```
   ## Analysis report — [date]

   ### Coverage
   - Total user stories: N
   - Stories with ≥1 task: N (X%)
   - Total tasks: N
   - Tasks with [USN] label: N (X%)

   ### Findings

   | Severity | Location | Finding |
   |----------|----------|---------|
   | CRITICAL | T006 verify: mdbook-builds | Criterion is `test -d "$out/docs/book"` — passes if build produced empty output |
   | HIGH     | US12 | No task with [US12] label in tasks.md |
   | MEDIUM   | T014 | No [USN] label — cannot trace to a user story |
   | LOW      | T003 verify: file-exists | Bare `test -f` with no behavioral follow-up |
   ```

5. **Summarize** finding counts by severity. If all counts are 0:
   ```
   ✅ No findings — all user stories are covered, all tasks are traceable,
      no principle violations detected.
   ```

## Constraints — STRICTLY READ-ONLY

- Do **not** modify any file
- Do **not** fix the problems you find — report them only
- Do **not** create tasks, update plans, or add open questions
- Your entire output is to the conversation; zero file writes

User input: $ARGUMENTS
