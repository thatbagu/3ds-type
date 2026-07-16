---
description: Brownfield gap analysis — check Nix store against spec and append remaining work
handoffs:
  - label: Implement gaps
    agent: amonite.implement
    prompt: "Gaps appended to tasks.md — implement the new tasks"
    send: false
---

# Converge: Gap Analysis

Compare the current Nix store against `.amonite/{spec,plan,tasks}.md` to find remaining
work. When gaps exist, append them to `tasks.md` as new tasks. When none remain, report
✅ Converged.

**tasks.md is APPEND-ONLY** — never modify or rewrite existing entries.

## When to run

After `/amonite.implement` to check what remains. Iterate: converge → implement gaps →
converge again until fully converged.

## Primary verification signal

A task that is **in the Nix store** has passed its criteria hermetically. Use
`nix path-info` as the read-only existence check:

```bash
nix path-info .#task-TNNN 2>/dev/null && echo "verified" || echo "missing"
```

If `nix path-info .#task-TNNN` exits 0, the task is verified — skip it entirely.

## Steps

1. **Check the Nix store** for all tasks in `tasks.md`:
   ```bash
   for task in $(grep -oE '\bT[0-9]+\b' .amonite/tasks.md | sort -u); do
     if nix path-info ".#task-$task" 2>/dev/null; then
       echo "● $task"
     else
       echo "○ $task"
     fi
   done
   ```

2. **Classify each pending (○) task**:

   | Gap type | Meaning |
   |----------|---------|
   | `missing` | No implementation started — build script is still the placeholder |
   | `partial` | Store path absent but source files exist (build fails a verify entry) |
   | `contradicts` | Build exits 0 but a spec requirement is unmet (verify criterion mismatch) |

3. **Check user story coverage** — for each USN in spec.md:
   - All tasks verified ● → story is ✅ done
   - Some tasks pending ○ → story is ○ in-progress
   - No tasks with that `[USN]` label → story is completely unimplemented (new task needed)

4. **If gaps exist**, append to `tasks.md`:
   ```markdown
   ## Convergence — [date]

   ### Pending tasks
   | Task | Gap type | Notes |
   |------|----------|-------|
   | T012 | partial  | verify_tfidf.py exists but cosine check fails at threshold 0.10 |
   | T015 | missing  | no implementation — build script is still the placeholder |

   ### Missing story coverage
   | Story | Note |
   |-------|------|
   | US14  | No tasks with [US14] label — run /amonite.tasks to scaffold |
   ```

   Rules:
   - Only append — never touch any existing line
   - Each converge run gets its own `## Convergence — [date]` section
   - Do not add rows for tasks already tracked in tasks.md

5. **If no gaps**:
   ```
   ✅ Converged — all N tasks verified in Nix store. No pending work.
   ```
   Do not modify `tasks.md` in this case.

## Constraints

- `tasks.md` is **APPEND-ONLY** — never modify existing content
- Use only `nix path-info` — do not run `nix build` (read-only store check)
- Do not start implementing gaps — that is `/amonite.implement`

User input: $ARGUMENTS
