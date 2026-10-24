# lajur

Indonesian traffic rules as a model a compiler can check, next to the statutes they come from.

Status: v0 slice. 19 rules, 9 scenarios, 10 laws. All proofs check with Bend 2.0.39.

## Why this shape

A quiz tells you the answer. A driving situation makes you choose before you know the answer, and the useful part comes after: which rule you broke, which article says so, and what it costs.

That feedback needs one rule set, not two. So the rules are data. The adjudicator returns rule ids; the catalogue turns an id into a citation, a tier, and a sanction. The explanation reads the same catalogue, so the text a player sees cannot drift from the logic that judged them.

Two more forces shape the model:

- **The law moves.** A third amendment to UU 22/2009 is in progress, with a target of 2026 for passage and 2027 for effect. Rules must carry an effective window, not sit in code.
- **Not every obligation has a sanction.** Pasal 108 requires the left lane, but the criminal chapter assigns no fine for a private driver. The model records zero, not a guess.

## Layout

```text
laws/    the statutes, unmodified, plus an index with checksums and sources
bend/    the model: rules.bend, LAWS.bend, PROOF.bend
docs/    scope, precedence, corpus, known gaps
```

## The model

`bend/rules.bend` holds three things:

- **Scenario.** A record of six groups: road, load, equipment, motion, priority, papers.
- **Catalogue.** 19 rules. Each carries `tier`, `months`, `fine`, `instrument`, `article`.
- **Adjudicator.** `charges(scenario)` returns violated rule ids in ascending order. Nothing else.

`bend/LAWS.bend` states ten claims and `bend/PROOF.bend` proves them.

| Law | What it pins down |
| --- | --- |
| `catalogue_size` | The catalogue has exactly 19 rules. |
| `citations_complete` | Every rule names a non-empty instrument and article. |
| `speed_limits_match_pm_111_2015` | 30 / 50 / 80 / 100 km/h by zone. |
| `tiers_match_precedence` | Signal outranks sign, sign outranks marking, where the catalogue uses them. |
| `sanctions_match_statute` | 14 rules carry the months and rupiah the statute states. |
| `corpus_matches_golden` | 9 scenarios produce their recorded verdicts. |
| `corpus_ids_are_catalogued` | Every id the corpus emits exists in the catalogue. |
| `helmet_charged_iff_unhelmeted` | Rule 7 fires exactly when the rider has no helmet. |
| `passenger_limit_is_one` | Rule 9 fires at 2 and 3 passengers, not at 0 or 1. |
| `seatbelt_charged_iff_car` | Rule 10 fires for cars, never for motorcycles. |

The proofs are not decoration. Change a fine in the catalogue and `sanctions_match_statute` fails. Add a rule without an article and `citations_complete` fails. Emit an id that is not in the catalogue and `corpus_ids_are_catalogued` fails.

## Run the checks

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
export PATH="$HOME/.bend/bin:$PATH"

cd bend
bend PROOF.bend
```

Expected output:

```text
ALL PROOFS CHECK
```

`bend PROOF.bend --verdict` re-checks the proofs with Bend's Lean kernel. It needs Lean 4.34.0 and was not run here, so the current evidence is Bend's own checker only.

## What the checks cover, and what they do not

Covered: the shape of the catalogue, the presence of citations, the transcribed sanctions, the speed limits, nine golden verdicts, and two rule-level biconditionals.

Not covered:

- **Legal reading.** The model encodes the plain text of the cited articles. It is not legal advice, and it does not resolve conflicting local practice.
- **Sequence.** A scenario is one moment. Following too closely, and the duty to slow before a hazard, need time, so they are out of the slice.
- **Unbounded counts.** The passenger law checks 0 to 3 passengers, the range the scenarios use. A proof for every natural number needs induction the current model does not carry.
- **Local rules.** Provincial and municipal regulations add signs and limits. They are out of scope until the rule package has a jurisdiction field.

## Roadmap

1. **v0, this commit.** 19 rules, 9 scenarios, 9 proven laws.
2. **v0.1.** Scenario JSON, a TypeScript port of the adjudicator, and a harness that runs the same corpus in both. The game needs the port; the proofs keep it honest.
3. **v0.2.** Rule packages with `effective_from` and `effective_to`, plus the third amendment once it is enacted.
4. **v1.** A playable slice: short situations, a verdict with the article, and a pre/post quiz that measures learning.

## Sources

| Instrument | Why it is here | File |
| --- | --- | --- |
| UU 22/2009 | The statute. Obligations, prohibitions, sanctions. | `laws/uu-22-2009-lalu-lintas-dan-angkutan-jalan.pdf` |
| PP 30/2021 | Implementing regulation. | `laws/pp-30-2021-penyelenggaraan-llaj.pdf` |
| PP 37/2017 | Road safety. | `laws/pp-37-2017-keselamatan-llaj.pdf` |
| PP 79/2013 | Road network and class, which speed limits attach to. | `laws/pp-79-2013-jaringan-llaj.pdf` |
| PM 13/2014 | Traffic signs, shapes, colours, meanings. | `laws/pm-13-2014-rambu-lalu-lintas.pdf` |
| PM 111/2015 | The numeric speed limits. | `laws/pm-111-2015-batas-kecepatan.pdf` |
| Perpol 5/2021 | The SIM exam this audience prepares for. | `laws/perpol-5-2021-sim.pdf` |
| UU 28/2014 | Pasal 42: no copyright in statutes, so the text is reusable. | `laws/uu-28-2014-hak-cipta.pdf` |

See [`laws/README.md`](laws/README.md) for pages, checksums, and download sources.

## Reuse

The PDFs are statutes and regulations. Under Pasal 42 of UU 28/2014 they carry no copyright, and they are stored here unmodified. Code in this repository is MIT.

This project is not affiliated with, endorsed by, or connected to POLRI, Korlantas, or Kementerian Perhubungan. Do not use their logos or present the model as official guidance.
