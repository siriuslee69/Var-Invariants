switch("path", "src")

## Shared pragma module: one file for the whole workspace, so there is no
## per-repository copy to drift or to collide on the Nim path.
##
## Both places are offered, and the order matters: Nim takes the LAST
## matching `--path` entry, so the pinned submodule wins when it is there
## and the sibling clone is the fallback.
if dirExists(thisDir() & "/../Rune-Pragmas/meta"):
  switch("path", thisDir() & "/../Rune-Pragmas/meta")
if dirExists(thisDir() & "/submodules/Rune-Pragmas/meta"):
  switch("path", thisDir() & "/submodules/Rune-Pragmas/meta")

## Build presets: configs/default.toml, plus configs/<name>.toml with -d:preset=<name>.
when fileExists(thisDir() & "/../Nimble-Tasks/src/preset.nims"):
  include "../Nimble-Tasks/src/preset.nims"
elif fileExists(thisDir() & "/submodules/Nimble-Tasks/src/preset.nims"):
  include "submodules/Nimble-Tasks/src/preset.nims"
else:
  proc applyPreset() = echo "config.nims: Nimble-Tasks/src/preset.nims not found; configs/*.toml ignored."
applyPreset()
