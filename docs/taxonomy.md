# Categories

A statute mixes several kinds of statement. "Wear a helmet" is a duty you can
break in a second. "The Minister sets the speed limit" is a power. "Five years"
is a number. Modelling all three the same way produces a catalogue that cannot
be checked.

So each provision is sorted into one category first, and each category has its
own way of being stated and checked. This note lists the categories, what they
look like in the text, and where they end up in `bend/`.

## The twelve categories

| # | Category | Marker in the text | Modelled as | Checked by |
| --- | --- | --- | --- | --- |
| 1 | Definition | `yang dimaksud dengan`, a numbered list under Bab I | A datatype: `M.Zone`, `M.Sim`, `V.Item` | Every member exists, and a law names the list length |
| 2 | Principle | `asas`, `bertujuan`, `ruang lingkup` | Not modelled. It guides interpretation and binds no one in a moment. | — |
| 3 | Competence | `Menteri menetapkan`, `Gubernur menyusun`, `Bupati` | A function from facts to an authority: `SV.approval_authority` | `law a_national_road_puts_approval_with_the_minister` |
| 4 | Duty | `wajib`, `harus` | A scenario rule in `R.catalogue()` | One law per rule, e.g. `law bike_driver_must_wear_helmet` |
| 5 | Prohibition | `dilarang`, `tidak boleh` | The same catalogue, same shape | `law no_racing`, `law a_bicycle_may_not_hold_on` |
| 6 | Permission | `berhak`, `dapat`, `boleh` | A predicate on a licence or a road: `M.sim_public`, `R.accessory_allowed` | `law a_personal_licence_is_not_for_public_carrying` |
| 7 | Procedure | `tata cara`, `jangka waktu`, `paling lama` | A step count and a deadline: `L.issue_steps`, `S.system_deadline_months` | `law issuing_a_licence_runs_five_steps` |
| 8 | Standard | a number with a unit: `3.500 kg`, `100 km/jam`, `60 sentimeter` | A table: `M.speed_limit`, `M.class_max_width`, `N.shoulder_clearance_cm` | One law per value |
| 9 | Sanction | `dipidana`, `denda paling banyak` | `months`, `days` and `fine` on the rule the sanction punishes | `law helmet_costs_one_month_and_250000` |
| 10 | Delegation | `diatur dengan Peraturan Pemerintah` | The instrument hierarchy: which regulation implements which article | `M` records the instruments; this slice models the implementing text itself |
| 11 | Transition | `mulai berlaku`, `dicabut dan dinyatakan tidak berlaku` | Not modelled yet. An effective window is roadmap, not this slice. | — |
| 12 | Declarative | descriptive prose with no actor and no duty | Not modelled. | — |

Categories 2, 11 and 12 are deliberately outside the model. A principle has no
addressee in a moment, a transition needs a clock the slice does not carry, and
a declarative sentence states no requirement. Modelling them would add text
without adding a claim.

## Why a category, not a rule, is the unit

The statutes are not uniform. UU 22/2009 carries 326 articles, of which about
50 bind a driver in a situation and the rest allocate powers, define terms, set
numbers, or describe procedure. Perpol 5/2021 carries 47 articles and almost
none of them are about a moment: they are requirements, stages and deadlines.

A model that treats every article as a scenario rule would have to invent a
scenario for "the Minister coordinates the pillar". A model that treats every
article as data would say nothing about a helmet. Sorting first is what lets
the helmet become a law and the pillar become a constant.

## Counts

Across the eight instruments, `corpus/provisions.json` holds 2081 provisions:
786 from UU 22/2009, 341 from PP 79/2013, 312 from UU 28/2014, 211 from
PM 13/2014, 167 from Perpol 5/2021, 149 from PP 37/2017, 92 from PP 30/2021 and
23 from PM 111/2015.

The Bend model states 176 laws over them. The count per instrument is in the
[README](../README.md#what-is-modelled).

## What this buys

Each law is a claim a compiler checks, so a wrong number fails the build:

```text
law a_motorway_is_100:
  { M.speed_limit(M.Motorway{}) == 100 : U32 }
```

Change the table to 110 and the proof stops checking. That is the whole point
of writing the number down twice: once where the model uses it, once where the
statute states it.
