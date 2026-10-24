# Claims about the rule model. Each law is proven in PROOF.bend.
import Base
import ./rules.bend as R

law catalogue_size:
  { R.catalogue_count() == 19n : Nat }

law citations_complete:
  { R.catalogue_citations_ok(R.catalogue()) == True{} : Bool }

law speed_limits_match_pm_111_2015:
  { R.speed_limits_ok() == True{} : Bool }

law tiers_match_precedence:
  { R.tiers_ok() == True{} : Bool }

law sanctions_match_statute:
  { R.sanctions_ok() == True{} : Bool }

law corpus_matches_golden:
  { R.corpus_passes() == True{} : Bool }

law corpus_ids_are_catalogued:
  { R.corpus_catalogued() == True{} : Bool }

law helmet_charged_iff_unhelmeted:
  for h: Bool
  { R.contains(7, R.charges(R.bike_helmet(h))) == Bool.not(h) : Bool }

law passenger_limit_is_one:
  { R.passenger_counts_ok() == True{} : Bool }

law seatbelt_charged_iff_car:
  for m: Bool
  { R.contains(10, R.charges(R.seatbelt_case(m))) == Bool.not(m) : Bool }
