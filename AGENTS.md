# Working on lajur

The laws are Bend programs. A change is done when the proofs check.

## Checks

```sh
cd bend
bend PROOF.bend              # Bend's checker
bend PROOF.bend --verdict    # the same proofs through the Lean kernel
```

Both checks run in CI on every push, after `tools/check_citations.py`, which
checks that the article each rule names as its sanction really cites the
article it names as its duty, with the stated numbers. Run it after touching
the catalogue:

```sh
.venv/bin/python tools/check_citations.py
```

`.agents/setup` installs Bend 2.0.39 and the web packages in a fresh orb and
runs no proofs; the verdict needs Lean 4.34.0, which only CI installs.

## The game

`web/` is the driving game. The road, the traffic, the speed ceiling and the
verdicts are Bend: `web/logic/game.bend`, proved by `web/logic/PROOF.bend`. The
road is the generated world's (`web/logic/world.bend`): the car drives a route
of lattice legs, and a worker makes the cells around it ahead of the car.
TypeScript draws the result and decides nothing, so a rule that ships is a rule
that checks.

```sh
cd web
vp run proof             # bend logic/PROOF.bend
vpr proof --verdict      # the same through the Lean kernel
vp check                 # format, lint, types
vp run layers            # the town's numbers per layer, and a flat SVG per seed
vp run plan              # the lab world's checks, and a flat plan SVG per seed
vp dev                   # serves on $PORT
```

`src/game.mjs` is generated from the model by `vp dev` and `vp build`; do not
edit it. A change to the game is done when `vp run proof` prints ALL PROOFS
CHECK and the page still drives.

## Corpus

`corpus/` is generated from `laws/`. Rebuild it with
`.venv/bin/python tools/build_corpus.py` after touching the extractor, and keep
the diff, because the index carries the checksums of the PDFs.
