---
description: Produce the implementation plan and adjust the project meta flake
---

Create or update `.amonite/plan.md` from `.amonite/spec.md`, then apply the
meta-environment section to the project `flake.nix`, and write the task
dependency graph to `.amonite/task-graph.json`.

Gate: if spec.md has unresolved Open questions, STOP and surface them.

1. Fix the technical context: language, dependencies, storage, target.
2. Design the architecture; name components — tasks will map onto them.
3. Write the verification strategy table. For every layer decide: hermetic
   (unit in task derivations, integration in cluster verify / nixosTest)
   or gate.live (impure, manual). Anything you cannot verify hermetically
   MUST appear in gate.live — hiding impurity violates principle E2.
4. Sketch the cluster topology: which clusters exist, roughly which tasks
   feed them, APP at the top.
5. Apply the "Meta environment" package list to the project flake.nix at
   the `# amonite:toolchain` marker. Keep it minimal (principle E3):
   project-wide tools only; task-specific tools go into task envs later.
6. Write `.amonite/task-graph.json` — the machine-readable parallel
   execution plan. This file drives `amonite waves` and multi-agent
   dispatch. Format:
   ```json
   {
     "waves": [
       {
         "wave": 1,
         "tasks": [
           { "id": "T001", "title": "...", "cluster": "C001", "depends": [] },
           { "id": "T002", "title": "...", "cluster": "C001", "depends": [] }
         ]
       },
       {
         "wave": 2,
         "tasks": [
           { "id": "T003", "title": "...", "cluster": "C001", "depends": ["T001"] }
         ]
       }
     ]
   }
   ```
   Rules: wave 1 = tasks with no dependencies; wave N = tasks whose
   `depends` are all in waves < N. A task marked [P] in tasks.md with
   no unresolved `depends` belongs in wave 1. Do not invent dependencies;
   if two tasks are truly independent, put them in the same wave.
7. Run `nix flake check` on the project root; the flake must still
   evaluate. Fix if broken.
8. Re-check the whole plan against `.amonite/principles.md`.

User input: $ARGUMENTS
