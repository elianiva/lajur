# Working on lajur

The laws are Bend programs. A change is done when the proofs check.

## Checks

```sh
cd bend
bend PROOF.bend              # Bend's checker
bend PROOF.bend --verdict    # the same proofs through the Lean kernel
```

`.agents/setup` installs Bend 2.0.39 and Lean 4.34.0 in a fresh orb. Both checks
run in CI on every push.

## Corpus

`corpus/` is generated from `laws/`. Rebuild it with
`.venv/bin/python tools/build_corpus.py` after touching the extractor, and keep
the diff, because the index carries the checksums of the PDFs.
