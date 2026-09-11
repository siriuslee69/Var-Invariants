## ============================================================
## | Var-Invariants Public Module                             |
## | -> `needs`, `gives`, `keeps` and their `Run` tier        |
## ============================================================
##
## One import for everything this repository offers:
##
##     import var_invariants
##
##     proc withdraw(balance, amount: int): int {.
##       needs: amount <= balance,
##       gives: result >= 0
##     .} =
##       balance - amount

import ./protocols/invariants

export invariants
