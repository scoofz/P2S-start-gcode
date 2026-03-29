# Bambu Lab P2S — Optimized Start G-code

A cleaned-up and fixed version of the stock Bambu Lab **P1S / P2S** start g-code (BambuStudio, 2026-02-26 revision), addressing two annoying stock behaviors: redundant homing cycles and delayed motor noise reduction.

However, keep in in mind that the Bambu P2S firmware's internal G28 macro always performs a quadruple X+Y homing cycle regardless of axis specified. This is hardcoded in the firmware and cannot be fixed from the start g-code. This fix removes one unnecessary G28 call (the unconditional one after bed leveling), reducing the total from 4 to 3 full homing cycles. A full resolution would require a firmware-level fix from Bambu.


---

## What's wrong with the stock start g-code?

### Bug 1 — Unnecessary full XYZ rehome after bed leveling

In the stock sequence, a bare `G28` sits **unconditionally** right after the bed leveling block, outside any conditional (`M622`/`M623`) guard:

```gcode
M622 J0
  G28       ; ← correct: homing only when ABL is skipped
M623
G29.2 S1
G28         ; ← BUG: runs unconditionally, every single print
```

This means the printer performs a full XYZ homing **every time**, regardless of whether bed leveling was done or not — in addition to the initial homing already performed earlier in the sequence.

**Fix:** The unconditional `G28` is removed. The `G28` inside the `M622 J0` block (no-ABL path) is left intact, as it is intentional and correct.

---

### Bug 2 — Motor noise reduction activated too early to be effective

The stock sequence calls `M982.2 S1` (cog noise reduction) **before** `M975 S1` (input shaping) in the machine reset section:

```gcode
M983.1 M1
M982.2 S1   ; ← noise reduction, but input shaping isn't active yet
M983.4 S0
```

`M982.2` depends on `M975` being active to have any effect. In the stock code, `M975 S1` is only called much later (after the mechanical sweep), so the noise reduction does nothing during the noisiest parts of the startup sequence.

**Fix:** `M975 S1` is moved immediately before `M982.2 S1` in the reset block, so noise suppression is effective from the very beginning.

---

## Changes summary

| # | Location | Stock behavior | Fixed behavior |
|---|----------|---------------|----------------|
| 1 | After bed leveling | Unconditional `G28` re-homes every print | `G28` removed; homing only inside the no-ABL conditional path |
| 2 | Machine reset section | `M982.2 S1` called before `M975 S1` | `M975 S1` moved before `M982.2 S1` so noise reduction is immediately active |

---

## How to use

1. In **BambuStudio**, go to **Printer Settings → Machine G-code → Machine start G-code**
2. Select all and delete the existing content
3. Paste the contents of `start_gcode_P2S_fixed.gcode`
4. Save your profile to a new P2S profile, Bambu Studio doesn't allow to override the starting gcode under the original profile. 
5. Remember to select it before starting a print. 

> **Note:** This was written and tested against the `2026-02-26` revision of the stock P2S start g-code. 

---

## Compatibility

- Bambu Lab **P2S** (primary target)
- Likely compatible with **P1S** — the g-code structure is nearly identical, but use at your own risk
- BambuStudio / Orca Slicer

---

## Contributing

Spotted another quirk in the startup sequence? PRs and issues welcome.
