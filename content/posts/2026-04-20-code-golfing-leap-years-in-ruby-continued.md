+++
date = '2026-04-20T14:05:20+02:00'
title = 'Code Golfing Leap Years in Ruby (continued)'
draft = true
+++

  451.upto(600){_1%25<1&&_1%4>0||p _1*4}

  Two logical reductions:

  1. %100 → %4 — When _1 % 25 == 0, then _1 = 25k. Since 25 ≡ 1 (mod 4), it follows that _1 % 4 = k % 4. And _1 % 100 = 0 ⇔ k % 4 = 0. Both tests are therefore equivalent, but %4 saves two characters.

  2. Modifier-if → short-circuit — p(x)if !condition becomes condition||p(x). By negating the condition (skip-condition instead of print-condition), the if including its space disappears. When _1%25<1 &&
  _1%4>0 is true (multiple of 25 but not of 4 — the secular years to skip), || returns the left operand and p is not invoked.

  Verification of the critical cases in 451..600:
  - 475 (→ 1900): 0<1 && 3>0 = true → skipped ✓
  - 500 (→ 2000): 0<1 && 0>0 = false → printed ✓
  - 600 (→ 2400): 0<1 && 0>0 = false → printed ✓

