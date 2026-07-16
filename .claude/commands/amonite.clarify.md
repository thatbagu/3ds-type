---
description: Structured Q&A to resolve spec ambiguities before planning
handoffs:
  - label: Plan
    agent: amonite.plan
    prompt: "Spec clarified — produce the implementation plan"
    send: true
---

# Clarify the Specification

Ask up to 5 targeted questions to resolve ambiguities in `.amonite/spec.md` before
architecture is fixed in `plan.md`. Each accepted answer is written back into spec.md
under `## Clarifications` — a permanent artifact of the decisions made.

## When to run

After `/amonite.specify` and before `/amonite.plan`. Skip if the spec is already
unambiguous — forced clarification on a clear spec wastes time.

## Steps

1. **Read `.amonite/spec.md`** in full. Note every "Done when" bullet and open question.

2. **Identify ambiguities** that would cause plan rework if resolved after architecture
   is fixed. Good targets:
   - "Done when" bullets that say "works correctly" or "fast enough" (non-observable)
   - User stories with no observable verification signal
   - Stories that assume a technology choice not stated in the spec
   - Scope boundaries that overlap with "Out of scope" items
   - Open questions that could be answered right now with a simple user choice

3. **Ask questions one at a time**, max 5 total. For each question:
   - State what is ambiguous and why it matters for architecture
   - Give a concrete recommendation with brief rationale
   - Offer 2–3 numbered options
   - Wait for the answer before asking the next question

   Format:
   ```
   **Q1 — [topic]:** [question text]

   Recommendation: option N because [reason].

   1. [option A]
   2. [option B]
   3. Other — tell me
   ```

4. **Write accepted answers into spec.md** under `## Clarifications` (create the
   section if absent):
   ```markdown
   ## Clarifications

   - **Q1** ([topic]): [decision] — resolved [date]
   - **Q2** ([topic]): [decision] — resolved [date]
   ```
   Do not modify user stories or any other section — only add/update `## Clarifications`.

5. **Resolve open questions** in spec.md `## Open questions`. For each:
   - If the clarification session answered it: move it to `## Clarifications` as resolved
   - If still open: note what external information is needed and leave it open

## Done when

- [ ] `## Clarifications` section exists in `.amonite/spec.md`
- [ ] Every "Done when" bullet in the clarified stories names a specific output,
      exit code, or measurable signal (not "works correctly", "is fast", "looks good")
- [ ] No more than 5 questions were asked
- [ ] All open questions are either resolved or explicitly deferred with a note

## Constraints

- Only modify `## Clarifications` and `## Open questions` in spec.md
- Do not begin planning or decomposing tasks — that is `/amonite.plan`
- If the spec is already unambiguous, say so explicitly and hand off immediately
