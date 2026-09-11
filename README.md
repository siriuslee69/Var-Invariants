# Var-Invariants

Promises a routine has to keep, written next to the routine and
actually checked.

Named for Vár, who in the old stories hears the promises people make
to one another and holds them to what they said.

---

## Installation

This is a library. Nothing is built and nothing is installed as a
program; a repository puts it on its Nim path and imports it.

### NixOS / Linux

```sh
cd ~/where/your/repos/live
git clone https://github.com/siriuslee69/Var-Invariants.git
git clone https://github.com/siriuslee69/Rune-Pragmas.git   # if not already there
```

### Windows 11

```powershell
cd C:\where\your\repos\live
git clone https://github.com/siriuslee69/Var-Invariants.git
git clone https://github.com/siriuslee69/Rune-Pragmas.git
```

### Using it from your own repository

Two ways, and the second is what the repositories here do.

**As a sibling clone.** Add one line to your `config.nims`:

```nim
if dirExists(thisDir() & "/../Var-Invariants/src"):
  switch("path", thisDir() & "/../Var-Invariants/src")
```

**As a pinned submodule**, so the version is recorded:

```sh
git submodule add https://github.com/siriuslee69/Var-Invariants.git \
  submodules/Var-Invariants
```

```nim
# config.nims - the submodule wins when it is there, because Nim takes
# the LAST matching --path entry.
if dirExists(thisDir() & "/../Var-Invariants/src"):
  switch("path", thisDir() & "/../Var-Invariants/src")
if dirExists(thisDir() & "/submodules/Var-Invariants/src"):
  switch("path", thisDir() & "/submodules/Var-Invariants/src")
```

Either way, one import:

```nim
import var_invariants
```

**One thing it needs.** `Rune-Pragmas` must be on the Nim path as
well, because the routines in here declare their roles the way every
repository in this workspace does. Every repository already has those
two lines in its `config.nims`; if yours does not, copy them from
`config.nims` here.

### Checking that it works

```sh
cd Var-Invariants
nimble test         # nine tests, including the two that compile programs
nimble runExample   # prints 7
```

`nimble test` takes a moment. Four of its tests build whole programs
in a scratch folder, because some of what is claimed here can only be
proved by compiling something and looking at what came out.

---

## What this is, in plain words

╭⟢ The problem 🌊

A routine's signature says what goes in and what comes out:

```nim
proc withdraw(balance, amount: int): int
```

Two numbers in, one number out. True, and not the important part. The
important part is the sentence nobody can fit in there:

> you must not take out more than is in the account

So that sentence goes in a comment. A comment is not checked by
anything. Six months later the routine has changed, the comment has
not, and now it is a lie that looks like documentation.

╭⟢ The idea ❧

Write the sentence where the compiler can see it:

```nim
import var_invariants

proc withdraw(balance, amount: int): int {.
  needs: amount <= balance,
  gives: result >= 0
.} =
  balance - amount
```

`needs` is the sentence about what comes in. `gives` is the sentence
about what goes out. `result` is the Nim word for what the routine
hands back. Both are now checked, and a comment that used to rot is
now something that breaks a build when it stops being true.

╭⟢ The three words ⟡

```
            checked            what it says
          ┌───────────────┬──────────────────────────────┐
 needs    │ on the way in │ "I refuse bad input."        │
 gives    │ on the way out│ "I promise good output."     │
 keeps    │ at BOTH ends  │ "I do not break this."       │
          └───────────────┴──────────────────────────────┘
```

**Def. 1 — precondition.** A sentence that must be true *before* a
routine runs. Written with `needs`.

**Def. 2 — postcondition.** A sentence that must be true *after* it
has run. Written with `gives`.

**Def. 3 — invariant.** The *same* sentence, required at both ends. It
was true when we arrived, and this routine has not broken it. Written
with `keeps`. That is the whole difference between `keeps` and the
other two, and it is why the repository is called what it is.

---

## The two tiers, and where each check happens

╭⟢ Six words, not three 🐦‍🔥

Each of the three has a second form ending in `Run`:

```
  needs      gives      keeps        <- checked while BUILDING
  needsRun   givesRun   keepsRun     <- checked while building
                                        AND while running
```

**Def. 4 — build time.** The moment the compiler is turning your text
into a program. The compiler can *run* Nim code at this moment - it
has a small interpreter inside it for exactly that.

**Def. 5 — run time.** The moment the finished program is running on
somebody's machine.

╭⟢ Why the first three are free ⟡

The check the first three write looks like this:

```nim
when nimvm:                      # <- only the compiler's interpreter
  if not (amount <= balance):    #    ever walks down this branch
    contractFailed("...")
else:
  discard                        # <- this is what the program gets
```

`nimvm` is a branch the compiler keeps for itself and never writes
into the finished program. So the program gets `discard`, which is
nothing at all.

Not "almost nothing". `nimble test` compiles two programs - one with
the promises written on it, one without - and checks that the two
files are the same number of bytes:

```
  sz_bare   ┌──────────────────────┐
            │ no promises written  │  73320 bytes
            └──────────────────────┘
  sz_deal   ┌──────────────────────┐
            │ needs + gives on two │  73320 bytes   <- identical
            │ routines             │
            └──────────────────────┘
```

(Those two numbers are one measurement, taken with Nim 2.2.10 on
x86-64 Linux at `-d:release`. The number itself will differ on your
machine; the only thing claimed here is that the two are equal.)

(Both stems are seven letters long on purpose. The compiler writes the
module's name into the binary, so a longer name would be a longer file
and would read as the promises costing something.)

╭⟢ So when does a build-time check ever fire? ❧

Whenever the compiler itself runs the routine. That happens in three
places: a `const`, a `static:` block, and inside any macro.

```nim
static:
  discard withdraw(100, 40)     # checked, and passes
  discard withdraw(40, 100)     # the build stops here, and says why
```

```
needs failed in `withdraw`: amount <= balance [ContractDefect]
```

This is worth being blunt about, because it is the one thing people
get wrong: **a routine that is only ever called while the program
runs is never checked by the first three.**

```
        who calls it            needs/gives/keeps    needsRun/...
      ┌──────────────────────┬───────────────────┬────────────────┐
      │ a const              │   checked         │   checked      │
      │ a static: block      │   checked         │   checked      │
      │ a macro              │   checked         │   checked      │
      │ the running program  │   NOT checked     │   checked      │
      └──────────────────────┴───────────────────┴────────────────┘
```

╭⟢ How the two are meant to be used together 🍣

Name the promise once with the `Run` form. Then a test that runs it in
a `static:` block catches a break while building, and the program
catches one that only a real user could produce.

A broken `Run` promise raises `ContractDefect` - a `Defect`, not an
`Error`, on purpose: this is a bug in the program, not a situation the
program was meant to cope with.

```
  ordinary build        checks are ON
  -d:danger             off
  -d:noVowContracts     off
  -d:vowContracts       ON, whatever else was said
```

---

## Saying more than one thing at a time

╭⟢ About every item, or about at least one 🌊

```nim
gives: forall(i in 1 ..< A.len, A[i - 1] <= A[i])   # A comes back sorted
needs: exists(c in s, c == '=')                     # s has an equals sign
```

`forall` is true when the second part holds for **every** one.
`exists` is true when it holds for **at least one**. Both stop at the
first answer that settles it. Both are ordinary expressions, so they
work in either tier and can be joined with `and` and `or`.

╭⟢ About the value something used to have ⟡

```nim
proc push(S: var seq[int], v: int) {.givesRun: S.len == old(S).len + 1.} =
  S.add(v)
```

`old(x)` is the value `x` held when the routine started:

```
   time ──────────────────────────────────────────────►

   S = @[1, 2]            S.add(v)             S = @[1, 2, 7]
        │                                            │
        └── old(S) is this ────────────┐             │
                                       ▼             ▼
                              old(S).len + 1  ==  S.len
                                    3               3   ✓
```

It costs one copy of `x`, so it is worth having only where a copy is
already being paid for - which is why it belongs with the `Run` tier.

---

## The one thing to watch

╭⟢ What `gives` had to do to your body ❧

A `gives` check has to happen after **everything**, including after an
early `return`. A check written after a plain body would simply be
jumped over:

```
   proc classify(a: int): string =
     if a > 0:
       return "high"    ───────┐   jumps out of the routine
     result = "low"            │
                               │
     if not (result.len > 0):  │   <- never reached. A promise
       contractFailed(...)  ◄──┘      nobody checks is worse than
                                      no promise at all.
```

So the body is wrapped in a block, and every `return` inside it is
rewritten:

```
   return x     becomes     result = x
                            break vowContractBody
```

A `return` written inside a closure *inside* your body is left alone,
because that one returns from the closure. The rewrite never reaches
into a nested routine of any kind.

**The case to watch.** The body's last line is looked at once: if it
is an expression the routine could return, it becomes `result = <it>`.
The compiler decides that, through `when compiles(result = ...)`. The
one way this surprises someone is a last line that calls something
marked `{.discardable.}` whose type happens to match the return type -
that value now becomes the result, where before it was thrown away.

---

## Why the names are not `requires` and `ensures`

୨୧ Those two are taken, and taken in the worst possible way.

`requires` and `ensures` are pragmas the Nim compiler already knows.
They belong to **DrNim**, a separate build of the compiler that proves
them with a solver. The *ordinary* compiler reads them, checks that
what is written makes sense, and then does nothing whatsoever with it.

```
   written with requires/ensures      written with needs/gives
   ┌──────────────────────────┐      ┌──────────────────────────┐
   │ compiles                 │      │ compiles                 │
   │ looks checked            │      │ IS checked               │
   │ broken promise: silence  │      │ broken promise: build     │
   │                          │      │ stops, and says which     │
   └──────────────────────────┘      └──────────────────────────┘
```

A promise that looks checked and is not is worse than no promise, so
these are called something else. There is a regression test that pins
this down: it compiles a program with a broken `requires` and checks
that the build **succeeds**, which is the whole problem in one test.

---

## Layout

```
Var-Invariants/
├── src/
│   ├── var_invariants.nim          <- the one import
│   └── protocols/
│       └── invariants.nim          <- all of it, ~410 lines
├── evaluation/
│   └── tests/test_invariants.nim   <- nine tests
├── examples/
│   └── account/src/account.nim     <- one routine per idea
├── agents/PROGRESS.md
└── config.nims                     <- finds Rune-Pragmas
```

Inside `invariants.nim` the shape is: six pragma names on top of one
builder.

```
   needs ──┐
   gives ──┼─► buildContract(ckNeeds|ckGives|ckKeeps, cond, def, atRun)
   keeps ──┘                          │
   needsRun ──┐                       ├─► checkNode   the when nimvm: part
   givesRun ──┼───────────────────────┼─► wrapBody    the block + return rewrite
   keepsRun ──┘                       └─► oldSnapshots the copies for old(x)
```

Six names because six pragmas is the API - a person writes `needs` on
a routine, not `contract(ckNeeds)`. One builder because the three
sentences differ only in **where** the check is put.

---

## Nimble tasks

| task | what it does |
|---|---|
| `nimble test` | the nine tests, including the two that compile programs |
| `nimble smoke` | compile the library on its own and stop |
| `nimble runExample` | build and run `examples/account` |
| `nimble buildExample` | the same, in release mode, into `builds/` |
| `nimble autopush` | stage, refuse generated files, commit from `agents/PROGRESS.md`, push |
| `nimble switch` | toggle the checkout between `nightly` and `main` |
| `nimble applyNightly` | fast-forward `main` to `nightly` and push |
| `nimble find` | point submodules at local sibling clones |

---

## Issue Playbook

Things that are known, and are not going to surprise you twice.

╭⟢ `undeclared identifier: 'role'` when compiling against this ⟡

`Rune-Pragmas` is not on your Nim path. Add the two lines from
`config.nims` here to yours, or clone `Rune-Pragmas` next to your
repository.

╭⟢ `invalid pragma: role: math` on a routine that also has a promise ⟡

The `needs` macro re-emits the whole pragma list, so every pragma
written in that block has to be visible where the routine is. If the
block mixes a role in with a promise, import both:

```nim
import var_invariants
import runePragmas
```

╭⟢ Otter reports the six macros as a "family" 🐦‍🔥

Otter's family check groups routines that are one routine with a knob
on it, and `needs`/`gives`/`keeps`/`needsRun`/`givesRun`/`keepsRun`
look exactly like that to it. They already *are* one routine with a
knob - `buildContract` - and the six names are the API surface: a
pragma is written by name, so the six names cannot be collapsed into
one without losing the whole point. The finding is expected here.

╭⟢ `contractFailed` and the placeholder guess 🍣

A body that only raises is one of the signals Otter adds up when
guessing whether somebody forgot to finish a routine. Here, refusing to
work *is* the job, so it carries `stage: stDone` to say so out loud.

That used to be reported anyway. A declared stage only skipped Otter's
"a pragma says this is unfinished" shortcut and left the guesses running
underneath it. Otter was changed at the same time as this split, so a
declared `stDone` is now a person's statement that outranks every guess.
With an Otter older than 2026-09-11 the finding comes back.

╭⟢ Otter reports the test as holding "embedded code" 🌊

Four of the tests build whole programs, and those programs are Nim
source kept in strings. Otter reads a multi-line string that looks like
code and says so. It is right, and it is meant to be that way: the
promise and the violation it is tested against are kept side by side so
the two cannot drift apart. The rule behind that finding is about the
comment marker to use inside such a block - here the embedded language
is Nim, so `#` is already correct.

╭⟢ A `gives` on a routine whose last line is `{.discardable.}` ❧

See "The one thing to watch" above. The discarded value becomes the
result. Write `discard theCall()` explicitly on that last line if that
is not what you wanted.

╭⟢ A build-time promise on a routine nothing calls at build time 🌊

It is never checked, and nothing tells you so. That is not a bug, it
is what "checked while building" means. Use the `Run` form, or call
the routine once from a `static:` block in a test.

---

## The conventions this repository is written to

A short form of the workspace rules, so a maintainer can read the code
without hunting for them.

╭⟢ Shape 🌊

- Nim, unless something says otherwise.
- Modules sorted by dependency level under `src/protocols/`.
- Every `.nim` file opens with a `##` box saying what it does.
- Tests, benchmarks and statistics live under `evaluation/`, never
  beside the code they measure.
- No nesting of loops or `if`s. Pull the inner block into an inline
  proc or a template instead.
- No backwards-compatibility shims. Breaking the API is fine; keeping
  dead code around to avoid it is not.

╭⟢ Declarations ⟡

- `var` and `const`, not `let`. `let` only where a routine has many
  branches and initialising per branch would be wasteful.
- Give every variable a starting value, and declare them in one
  indented block rather than repeating the keyword.
- No declarations inside loops.

```nim
var
  t: string = ""
  i: int = 0
```

╭⟢ Names ❧

- A parameter is named for the first letter of what it is.
- Lists, sequences and tables get a capital: `A`, `S`.
- `S` is a state object being changed; `S0`, `S1` if there are several.
- `i, j, k` are indices, `l, m, n` are lengths, `t` is temporary.
- Every parameter is explained on a `##` line under the declaration.

╭⟢ Pragmas 🍣

Every routine says what it is for, using the shared pragmas from
`Rune-Pragmas` - never a copy:

```nim
proc wrapBody(def: NimNode): NimNode {.compileTime, role: actor,
    tag: "contract".} =
```

`role` is what the routine is for. `tag` is a plain string, pieces
separated by `|`. `stage` is written only when a routine is *not*
finished - or, as with `contractFailed`, when a heuristic would
otherwise guess wrong. Evaluation routines carry `testKind`, and
`covers` naming what they test.

╭⟢ Placeholders 🐦‍🔥

A routine that does not do its job yet is named `ph_something`. No
exceptions - the prefix is what makes it findable later.
