# Project Principles

<!-- Persistent constitution. Every plan and task decomposition is checked
     against this file. Amend deliberately; agents may not weaken it. -->

## Product principles

- P1: Offline-first: once the phone and 3DS share a LAN, no internet connection is required — no telemetry, no cloud sync, no update checks, no remote logging.
- P2: Zero-latency feel: characters must appear on the 3DS screen with no perceptible delay from keypress — chord encoding and UDP dispatch happen synchronously in the keyboard event handler; no buffering or batching.
- P3: No install friction: the user configures once (APK sideload + Luma InputRedirection enabled + 3DS IP entered) — no per-session setup, no pairing ritual, no account.
- P4: Old-3DS compatible: all features must work on original 3DS hardware — no ZL/ZR, no New-3DS CPU speed mode, no IR-camera buttons. Button chord encoding is restricted to A/B/X/Y/L/R/Start/Select/D-pad (12 digital bits, 4096 combinations).

## Engineering principles

- E1: Every task's acceptance criteria MUST be mechanical: expressible as `verify` entries in its task.nix. "Looks correct" is not a criterion.
- E2: A task that cannot be verified hermetically MUST declare its impure boundary explicitly in the plan (see `gate.live` in plan.md).
- E3: Toolchain grants are minimal: a task's `env` lists only what that task needs. Widening an env is a plan change, not an implementation detail.
- E4: 3DS app: C++ with citro2d and libctru (devkitPro/devkitARM toolchain). Android app: Kotlin. No additional runtime dependency may be added to either side without a plan amendment.

## Non-negotiables

- N1: `nix flake check` green on the project root before any cluster is declared complete.
- N2: No data leaves the local network — the Android app opens no connections to any host outside LAN. Typed text may be persisted locally on Android at a user-configured path but must never be transmitted beyond the local network.
