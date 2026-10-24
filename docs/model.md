# The rule model

This note explains what `bend/rules.bend` encodes, which decisions it makes, and where it stops.

## Five rules of construction

1. **Rules are data.** The catalogue owns citation, tier, and sanction. The adjudicator owns detection only, and returns ids.
2. **Every rule names an article.** No article, no rule. `citations_complete` enforces this.
3. **No invented sanctions.** Where the statute assigns no fine or imprisonment to a private driver, the catalogue records zero.
4. **Precedence is explicit.** An officer's direction outranks a signal, a signal a sign, a sign a marking, and a marking the general rule. A conflict between two rules of equal tier is a modelling bug, not a judgement call. `tiers_match_precedence` checks the catalogue entries that carry signal, sign, and marking tiers.
5. **A scenario is one moment.** No history, no following distance, no closing speed. Those need time, and they are out of the slice.

## Scenario

A scenario is six records. Keeping them separate makes each constructor short enough to read and keeps field order honest.

| Group | Fields | Meaning |
| --- | --- | --- |
| `Road` | `zone`, `lane`, `police_directs`, `signal_red`, `sign_forbids`, `marking_forbids` | Where the vehicle is and what the road authority says |
| `Payload` | `vehicle`, `passengers`, `sidecar` | What is being driven and carried |
| `Equipment` | `rider_helmet`, `passenger_helmet`, `seatbelt`, `night`, `lights_on`, `phone` | What the driver and passengers wear or do |
| `Motion` | `speed`, `overtaking`, `overtake_side`, `front_signals_right`, `turning`, `indicates_turn` | What the vehicle is doing |
| `Priority` | `oncoming`, `oncoming_room`, `grade`, `yields_to_uphill`, `pedestrian_waiting`, `yields_to_pedestrian` | Who has right of way |
| `Papers` | `sim`, `stnk` | Documents the driver holds |

## Catalogue

`charges` returns ids in ascending order. `months` and `fine` are the statutory maximum: imprisonment in months, fine in rupiah.

| Id | Rule | Article | Sanction |
| --- | --- | --- | --- |
| 1 | Use the left side of the road | UU 22/2009 Pasal 108 ayat (1) and (2) | none stated |
| 2 | Overtake on the right | Pasal 109 ayat (1) | none stated |
| 3 | Do not overtake a vehicle that signals right | Pasal 109 ayat (3) | none stated |
| 4 | Give oncoming traffic room on the right | Pasal 110 ayat (1) | none stated |
| 5 | On a narrow grade, downhill yields to uphill | Pasal 111 | none stated |
| 6 | Signal before turning | Pasal 112 ayat (1) | 1 month, Rp250,000 (Pasal 294) |
| 7 | Rider wears a helmet | Pasal 106 ayat (8) | 1 month, Rp250,000 (Pasal 291 ayat (1)) |
| 8 | Passenger wears a helmet | Pasal 106 ayat (8) | 1 month, Rp250,000 (Pasal 291 ayat (2)) |
| 9 | One passenger at most without a sidecar | Pasal 106 ayat (9) | 1 month, Rp250,000 (Pasal 292) |
| 10 | Front occupants wear a seatbelt | Pasal 106 ayat (6) | 1 month, Rp250,000 (Pasal 289) |
| 11 | Full concentration, no phone | Pasal 106 ayat (1) | 3 months, Rp750,000 (Pasal 283) |
| 12 | Give way to pedestrians and cyclists | Pasal 106 ayat (2) | 2 months, Rp500,000 (Pasal 284) |
| 13 | Obey traffic signals | Pasal 106 ayat (4) huruf c | 2 months, Rp500,000 (Pasal 287 ayat (2)) |
| 14 | Obey signs | Pasal 106 ayat (4) huruf a | 2 months, Rp500,000 (Pasal 287 ayat (1)) |
| 15 | Obey markings | Pasal 106 ayat (4) huruf b | 2 months, Rp500,000 (Pasal 287 ayat (1)) |
| 16 | Lights at night, and by day on a motorcycle | Pasal 107 | 1 month, Rp250,000 (Pasal 293) |
| 17 | Stay within the limit for the zone | Pasal 21, PM 111/2015 | 2 months, Rp500,000 (Pasal 287 ayat (5)) |
| 18 | Carry a SIM | Pasal 106 ayat (5) huruf b | 1 month, Rp250,000 (Pasal 288 ayat (2)) |
| 19 | Carry an STNK | Pasal 106 ayat (5) huruf a | 2 months, Rp500,000 (Pasal 288 ayat (1)) |

Speed limits come from PM 111/2015: 30 km/h residential, 50 urban, 80 intercity, 100 motorway, with an absolute minimum of 60 on motorways under Pasal 21 ayat (4).

## Corpus

The corpus is a golden set. Each case names a situation and the ids the adjudicator must return. `corpus_matches_golden` proves the match.

| Case | Expected |
| --- | --- |
| Clean car | none |
| Motorcycle, rider without helmet | 7 |
| Motorcycle, two passengers, passenger without helmet | 8, 9 |
| Car, red light, phone, no seatbelt | 10, 11, 13 |
| Car, 45 km/h in a 30 zone | 17 |
| Motorcycle at night, lights off, downhill, pedestrian waiting | 5, 12, 16 |
| Car in the right lane, not overtaking | 1 |
| Car overtaking on the left of a car signalling right | 2, 3 |
| Car turning without signal, no SIM, no STNK | 6, 18, 19 |

Two rules of the corpus:

- **One violation per concern.** A case should isolate what it tests. An early draft of the overtaking case ran at 60 km/h in a 50 zone, and the verdict quietly gained rule 17. The golden set caught it.
- **Add a case with every rule.** A rule that no scenario exercises is a claim without a witness.

## Gaps

| Gap | Why it is open | What closes it |
| --- | --- | --- |
| Following distance, hazard braking | Needs time, not a moment | A scenario as a short trace instead of a record |
| Passenger counts beyond 3 | No induction over `Nat` in the current proofs | A recursive lemma over `Nat`, or a bounded domain type |
| Local limits and signs | Jurisdiction is not a field yet | `jurisdiction` and dated rule packages |
| The third amendment to UU 22/2009 | Not enacted | New rule package with an effective date, old one kept |
| Fines in practice | Court and police practice vary from the statutory maximum | Out of scope; show the statutory maximum and say so |

## Why Bend

The point of the slice is to make the rule set total and checkable: every charged id resolves, every rule cites an article, every transcribed sanction matches, and every scenario has a verdict. Bend forces all four, because a missing case or a drifted number fails the check.

Bend is not the runtime. The game will run TypeScript in a browser. Bend holds the specification and the proofs, and a TypeScript port runs the same corpus, so a divergence between the two is a test failure rather than a mystery.

## Adding a rule

1. Add the catalogue entry: id, tier, months, fine, instrument, article.
2. Add the condition in `charges`, in id order.
3. Add a corpus case that isolates it.
4. Run `bend PROOF.bend` in `bend/`.
5. If a law fails, the model changed in a way one of the laws pins down. Decide which is wrong before touching the law.
