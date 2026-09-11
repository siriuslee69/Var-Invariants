# Progress

Commit Message: Split the contract pragmas out of Otter into their own repository

Features (Planned):
- A `needs`/`gives` pair that reads the routine's own parameters out of
  the signature, so a promise cannot name something that is not there.
- Benchmarks under `evaluation/benchmarks/`: what `old(x)` actually
  costs for a large object, measured rather than reasoned about.

Features (Done):
- `needs`, `gives`, `keeps` - checked while the compiler runs a routine,
  and free in the finished program (`when nimvm:`).
- `needsRun`, `givesRun`, `keepsRun` - the same three, carried into the
  program as well, raising `ContractDefect`.
- `forall` / `exists` for saying something about every item, or one.
- `old(x)` for the value something held on the way in.
- `return` rewriting, so a `gives` cannot be stepped over by an early
  return; closures inside a body are left alone.
- Nine tests, four of which compile whole programs: the size-equality
  test that pins the zero-cost claim, and the regression test that pins
  why these are not called `requires`/`ensures`.
- `examples/account` - one routine per idea.

Features (In Progress):
- None.

Notes:
- Last big change: this code used to live in
  `Otter-RepoEvaluation/src/protocols/invariants.nim` and was exported
  from Otter's umbrella module. It is a library, not a measurement, so
  it was moved out on 2026-09-11. Otter now carries it as a submodule
  under `submodules/Var-Invariants` and no longer re-exports it.
- Two things changed in the move, both deliberate:
  1. The `otter` prefix on internal names became `vow` (Vár's domain is
     vows). The build switches are now `-d:noVowContracts` and
     `-d:vowContracts`; the block a `gives` wraps a body in is
     `vowContractBody`.
  2. `buildRequires` / `buildEnsures` / `buildInvariant` became one
     `buildContract` taking a `ContractKind`. Otter's family check was
     right that they were one routine with a knob on it.
- The module now imports `runePragmas` so its routines declare roles.
  That means `Rune-Pragmas` has to be on the Nim path of anything that
  compiles this. The test's two build helpers pass that path explicitly,
  because a scratch folder has no `config.nims` of its own.
- Otter fix made alongside: an explicit `stage: stDone` now clears the
  guessed placeholder signals in
  `Otter-RepoEvaluation/src/protocols/code_stats/placeholders.nim`.
  Before, a routine whose whole job is to raise was reported as
  unfinished no matter what it said about itself.
- Roles were added to every routine after the first Otter measurement of
  this repository reported 14 without one. That surfaced a real trap
  worth knowing: the `needs` macro re-emits the whole pragma list, so a
  routine writing `{.role: math, needs: ...}` needs `runePragmas`
  imported at its own site, not just here. The example shows both
  imports for that reason.
- Two Otter findings are expected and stay: the six macros read as a
  "family" (they are one builder with six API names, which is the point)
  and the test's generated programs read as "embedded code" (they are
  Nim, kept beside the promise they test so the two cannot drift).
