switch("path", "src")

## The library this example is an example of, and the shared pragmas it
## imports. Both are found by walking up out of `examples/account/`.
switch("path", thisDir() & "/../../src")

if dirExists(thisDir() & "/../../../Rune-Pragmas/meta"):
  switch("path", thisDir() & "/../../../Rune-Pragmas/meta")
if dirExists(thisDir() & "/../../submodules/Rune-Pragmas/meta"):
  switch("path", thisDir() & "/../../submodules/Rune-Pragmas/meta")
