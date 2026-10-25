# The model

This note explains how `bend/` turns the statutes into claims, which decisions
it makes, and where it stops.

## One law per requirement

A law names what it requires and states it fully. `bike_driver_must_wear_helmet`
is not a comment above a function; it is the claim that the adjudicator charges
rule 12 exactly when the rider has no helmet:

```text
law bike_driver_must_wear_helmet:
  for b: Bool
  { R.contains(12, R.charges(R.with_bike(0, b, True{}))) == Bool.not(b) : Bool }
```

Half of a law like that is a scenario. `R.with_bike(0, b, True{})` builds a
clean road, one motorcycle, no passenger, and sets the rider's helmet to `b`.
Everything else stays lawful, so the verdict isolates the one thing the rule is
about. That is why the fifty behaviour laws each vary a single flag.

## Five rules of construction

1. **Rules are data.** The catalogue owns citation, tier, and sanction. The
   adjudicator owns detection only, and returns ids.
2. **Every rule names an article.** No article, no rule. `every_rule_names_its_article` checks it.
3. **No invented sanctions.** Where the statute assigns no fine or imprisonment
   to a private driver, the catalogue records zero.
4. **Precedence is explicit.** An officer's direction outranks a signal, a
   signal a sign, a sign a marking, and a marking the general rule. An obeyed
   direction settles the charges below it, and disobeying it adds rule 6 to
   them: `an_obeyed_officer_outranks_a_red_light`, `..._a_sign` and
   `..._a_marking` prove that, and `tiers_follow_precedence` checks that the
   catalogue entries carry the tiers the order names.
5. **A scenario is one moment.** No history, no general following distance, no
   closing speed. Those need time. A posted following-distance sign reads the
   gap the act records, not a trace.

## Scenario

A scenario is six records and an act, so each constructor stays short enough to read.

| Group | Fields | Meaning |
| --- | --- | --- |
| `Road` | `zone`, `side`, `police_directs`, `obeys_officer`, `signal_red`, `sign_forbids`, `marking_forbids`, `railway_crossing`, `crossing_closed`, `roundabout`, `emergency_vehicle`, `goods_route_ok` | Where the vehicle is and what the road authority says |
| `Payload` | `vehicle`, `weight`, `cc`, `passengers`, `sidecar`, `overloaded`, `carries_people_in_truck`, `special_goods`, `special_goods_ok` | What is being driven and carried |
| `Equipment` | `rider_helmet`, `passenger_helmet`, `seatbelt`, `cabin`, `night`, `lights_on`, `phone`, `technical`, `roadworthy`, `spare_kit`, `plate`, `interference`, `holds_vehicle` | What the driver and passengers wear, do, or fail to carry |
| `Motion` | `speed`, `overtaking`, `overtake_side`, `front_signals_right`, `turning`, `indicates_turn`, `changing_lane`, `indicates_lane`, `racing`, `slowing`, `indicates_slow`, `stopping`, `parked_ok`, `emergency_stop`, `emergency_sign`, `leaves_accident`, `modified` | What the vehicle is doing |
| `Priority` | `oncoming`, `oncoming_room`, `grade`, `yields_to_uphill`, `pedestrian_waiting`, `yields_to_pedestrian`, `yields_to_emergency`, `at_junction`, `yields_right` | Who has right of way |
| `Papers` | `sim`, `sim_fits`, `stnk`, `kir`, `stops_at_terminal`, `manifest`, `passenger_insurance`, `crew_insurance` | Documents the driver holds |
| `Act` | `sign`, `turn`, `parking`, `lane_ok`, `chains`, `following_m`, `v_width`, `v_length`, `v_height`, `v_axle`, `lane`, `faster`, `sight_clear`, `room_ok`, `train_coming`, `crossing_traffic`, `yields_to_crossing`, `left_turn_allowed`, `hazard`, `bus_stopping` | The posted duty, the manoeuvre, and the facts a single rule reads that the six records do not carry |

## The rule catalogue

`R.charges` returns ids in ascending order, one per violation found. `months`,
`days` and `fine` are the statutory maximum: imprisonment and fine in rupiah.

| Id | Rule | Article | Sanction |
| --- | --- | --- | --- |
| 1 | Use the left side of the road | UU 22/2009 Pasal 108 ayat (1) | none stated |
| 2 | Overtake on the right, with a clear sight line and room | Pasal 109 ayat (1) | none stated |
| 3 | Do not overtake a vehicle that signals right | Pasal 109 ayat (3) | none stated |
| 4 | Give oncoming traffic room on the right | Pasal 110 ayat (1) | none stated |
| 5 | On a narrow grade, downhill yields to uphill | Pasal 111 | none stated |
| 6 | Obey an officer before a signal | Pasal 104 ayat (3) | 1 month, Rp250,000 (Pasal 282) |
| 7 | Stop at a red light | Pasal 106 ayat (4) huruf c | 2 months, Rp500,000 (Pasal 287 ayat (2)) |
| 8 | Obey a command or prohibition sign, including the duty it posts | Pasal 106 ayat (4) huruf a | 2 months, Rp500,000 (Pasal 287 ayat (1)) |
| 9 | Obey a road marking | Pasal 106 ayat (4) huruf b | 2 months, Rp500,000 (Pasal 287 ayat (1)) |
| 10 | Signal before turning | Pasal 112 ayat (1) | 1 month, Rp250,000 (Pasal 294) |
| 11 | Signal before changing lane | Pasal 112 ayat (2) | 1 month, Rp250,000 (Pasal 295) |
| 12 | Rider wears a helmet | Pasal 106 ayat (8) | 1 month, Rp250,000 (Pasal 291 ayat (1)) |
| 13 | Passenger wears a helmet | Pasal 106 ayat (8) | 1 month, Rp250,000 (Pasal 291 ayat (2)) |
| 14 | One passenger at most without a sidecar | Pasal 106 ayat (9) | 1 month, Rp250,000 (Pasal 292) |
| 15 | Seatbelt in a cabin | Pasal 106 ayat (6) | 1 month, Rp250,000 (Pasal 289) |
| 16 | Seatbelt and helmet in an open vehicle | Pasal 106 ayat (7) | 1 month, Rp250,000 (Pasal 290) |
| 17 | No phone while driving | Pasal 106 ayat (1) | 3 months, Rp750,000 (Pasal 283) |
| 18 | Give way to a pedestrian | Pasal 106 ayat (2) | 2 months, Rp500,000 (Pasal 284) |
| 19 | Lights at night | Pasal 107 ayat (1) | 1 month, Rp250,000 (Pasal 293 ayat (1)) |
| 20 | Motorcycle lights by day | Pasal 107 ayat (2) | 15 days, Rp100,000 (Pasal 293 ayat (2)) |
| 21 | Stay within the limit for the zone | Pasal 106 ayat (4) huruf g | 2 months, Rp500,000 (Pasal 287 ayat (5)) |
| 22 | Carry a licence | Pasal 106 ayat (5) huruf b | 1 month, Rp250,000 (Pasal 288 ayat (2)) |
| 23 | Carry a registration | Pasal 106 ayat (5) huruf a | 2 months, Rp500,000 (Pasal 288 ayat (1)) |
| 24 | Carry a test certificate | Pasal 106 ayat (5) huruf c | 2 months, Rp500,000 (Pasal 288 ayat (3)) |
| 25 | Stop at a crossing that is closed or has a train coming | Pasal 114 huruf a and b | 3 months, Rp750,000 (Pasal 296) |
| 26 | No racing | Pasal 115 huruf b | 1 year, Rp3,000,000 (Pasal 297) |
| 27 | Mark a breakdown (a motorcycle without a sidecar is exempt, Pasal 121 ayat (2)) | Pasal 121 ayat (1) | 2 months, Rp500,000 (Pasal 298) |
| 28 | Stay after a crash | Pasal 231 ayat (1) | 3 years, Rp75,000,000 (Pasal 312) |
| 29 | Park where it is allowed (the three grounds of Pasal 118) | Pasal 106 ayat (4) huruf e | 1 month, Rp250,000 (Pasal 287 ayat (3)) |
| 30 | Signal before slowing | Pasal 117 | none stated |
| 31 | Give way at an unguarded junction | Pasal 113 ayat (1) | none stated |
| 32 | Give way on a roundabout | Pasal 113 ayat (2) | none stated |
| 33 | Fit a number plate | Pasal 68 ayat (1) | 2 months, Rp500,000 (Pasal 280) |
| 34 | Four wheels must be roadworthy | Pasal 106 ayat (3) | 2 months, Rp500,000 (Pasal 286) |
| 35 | A motorcycle meets the technical rules | Pasal 106 ayat (3) | 1 month, Rp250,000 (Pasal 285 ayat (1)) |
| 36 | A car meets the technical rules | Pasal 106 ayat (3) | 2 months, Rp500,000 (Pasal 285 ayat (2)) |
| 37 | No accessory that endangers | Pasal 58 | 2 months, Rp500,000 (Pasal 279) |
| 38 | Carry the four-wheel kit | Pasal 57 ayat (3) | 1 month, Rp250,000 (Pasal 278) |
| 39 | A modification forces a retest | Pasal 52 ayat (2) | 1 year, Rp24,000,000 (Pasal 277) |
| 40 | A bicycle may not hold on | Pasal 122 ayat (1) | 15 days, Rp100,000 (Pasal 299) |
| 41 | Goods follow the named road class | Pasal 125 | 1 month, Rp250,000 (Pasal 301) |
| 42 | Public transport stops where allowed | Pasal 126 | 1 month, Rp250,000 (Pasal 302) |
| 43 | A goods vehicle does not carry people | Pasal 137 ayat (4) | 1 month, Rp250,000 (Pasal 303) |
| 44 | Special goods meet their rules | Pasal 162 ayat (1) | 2 months, Rp500,000 (Pasal 305) |
| 45 | Goods carry a manifest | Pasal 168 ayat (1) | 1 month, Rp250,000 (Pasal 306) |
| 46 | Do not overload | Pasal 169 ayat (1) | 2 months, Rp500,000 (Pasal 307) |
| 47 | Call at the terminal | Pasal 36 | 1 month, Rp250,000 (Pasal 276) |
| 48 | Insure the passengers | Pasal 189 | 6 months, Rp1,500,000 (Pasal 309) |
| 49 | Insure the crew | Pasal 237 ayat (2) | 6 months, Rp1,500,000 (Pasal 313) |
| 50 | Let the priority vehicle through | Pasal 134 | 1 month, Rp250,000 (Pasal 287 ayat (4)) |
| 51 | A motorcycle, a goods vehicle or a non-motorised vehicle keeps the left lane | Pasal 108 ayat (3) | none stated |
| 52 | The right lane serves a pass, a right turn, a U-turn or a faster vehicle | Pasal 108 ayat (4) | none stated |
| 53 | A left turn at a signal waits for a sign or an arrow | Pasal 112 ayat (3) | none stated |
| 54 | Give way to the vehicle already on the crossing | Pasal 114 huruf c | none stated |
| 55 | Slow before a stated hazard (the seven grounds of Pasal 116 ayat (2)) | Pasal 116 ayat (2) | none stated |
| 56 | Stop behind a bus taking passengers | Pasal 119 ayat (2) | none stated |

## The sign catalogue and its rules

`bend/signs.bend` transcribes every coded sign in PM 13/2014: 347 signs across
Tabel I to VI, plus the five kinds of papan tambahan. Each entry carries its
table, its group, its family, the regulation's meaning text, and an ordinal.

A warning or guidance sign carries `NoDuty`. Every prohibition and command
sign carries one operative rule in its `duty` field: 109 signs carry a duty.
`posted(code)` returns that duty, or `NoDuty` for a sign that only warns or
guides. The adjudicator applies the posted duty at rule 8, so a `III-3a`
(larangan berhenti) sign charges a driver who stops, and a `III-4b` (larangan
belok kiri) sign charges a driver who turns left.

`law stopping_at_a_no_stopping_sign_is_charged` is the whole chain: the code
names the sign, the rule table gives `NoStopping`, and `charges` returns rule 8
with its two months and Rp500,000.

```text
law stopping_at_a_no_stopping_sign_is_charged:
  { R.contains(8, R.charges(R.sign_stopping(M.NoStopping{}, True{}))) == True{} : Bool }
```

The subject table is coarser than the leaf. A bicycle is the one non-motorized
vehicle the scenario carries, and a public motor vehicle is the bus; a public
car is not distinguished. A variable limit of zero means the leaf states the
number and the model waits for a scenario to supply it.

## The other instruments

The catalogue is about a driver in a moment. The other instruments say things a
moment cannot express, so each has its own module and its own laws.

| Module | Instrument | What it models |
| --- | --- | --- |
| `model.bend` | PM 111/2015, PM 13/2014, Perpol 5/2021, PP 79/2013 | Speed by zone, sign families and duties, licence classes and validity, road classes |
| `signs.bend` | PM 13/2014 | Every coded sign, the operative rule each prohibition or command sign posts, supplement kinds |
| `network.bend` | PP 79/2013, PM 111/2015, PM 13/2014 | Road functions, class dimensions, where a limit may drop, sign placement |
| `licence.bend` | Perpol 5/2021 | Requirements, health checks, test stages, pass mark, retakes |
| `vehicle.bend` | UU 22/2009 Bab VII | Type test, periodic test, kit, technical items |
| `safety.bend` | PP 37/2017 | Five pillars, plan periods, safety management elements |
| `service.bend` | PP 30/2021, UU 22/2009 | Traffic impact analysis, terminals, papers, insurance |
| `works.bend` | UU 28/2014 | Copyright terms, and why a statute carries none |

## Corpus

`corpus/provisions.json` indexes every provision of the eight PDFs by article,
ayat and page. It is how a reader gets from `law a_motorway_is_100` back to
PM 111/2015 page 5. It is not an input to the model: the model states the law,
and the index says where the law is written.

`corpus/index.json` records, per instrument, the page count, how many pages are
body, how many articles were found, and any gap in the article sequence. All
eight instruments currently run 1..N with no gap.

## Gaps

| Gap | Why it is open | What closes it |
| --- | --- | --- |
| General following distance, hazard braking | Needs time, not a moment | A scenario as a short trace instead of a record |
| Passenger counts beyond 3 | No induction over `Nat` in the current proofs | A recursive lemma over `Nat`, or a bounded domain type |
| Local limits and signs | Jurisdiction is not a field yet | `jurisdiction` and dated rule packages |
| The third amendment to UU 22/2009 | Not enacted | New rule package with an effective date, old one kept |
| Principles, transitions, declarative text | They state no requirement a moment can break | Out of scope by design; see `docs/taxonomy.md` |
| Articles about permits and tariffs | They bind an operator's paperwork, not a driver | Modelled only where they change what is carried (`service.bend`) |
| Fines in practice | Court and police practice vary from the statutory maximum | Out of scope; show the statutory maximum and say so |
| Values printed on a leaf | A length, height, width, following distance or speed sign carries its number on the leaf; the rule table records a variable sign with a limit of zero | A scenario that supplies the number the leaf states |

## Why Bend

The point of the slice is that a law cannot quietly disagree with the model. A
wrong speed limit, a missing article, a penalty that drifts from the statute,
or a rule that fires when it should not all fail the build. Bend forces that,
because a claim that does not compute to `True` cannot be given a proof.

Bend is not the runtime. The game will run TypeScript in a browser. Bend holds
the specification and the proofs; a TypeScript port runs the same corpus, so a
divergence between the two is a test failure rather than a mystery.

## Adding a law

1. Find the provision in `corpus/provisions.json`.
2. Decide its category from `docs/taxonomy.md`.
3. Add the value or predicate to the module for that instrument.
4. State the law in `LAWS.bend`, named after the requirement.
5. Prove it in `PROOF.bend`, usually `{==}`.
6. Run `bend PROOF.bend`. If a law fails, decide which side is wrong before
   touching the other.
