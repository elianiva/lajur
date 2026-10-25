# The split laws alone, for iterating on them. PROOF.bend holds the same laws
# and is what CI runs.
#
#   cd web/logic && bend PROOF_SPLIT.bend
import Base
import ./town.bend as T

# ===========================================================================
# The split: streets inside a block
# ===========================================================================

# One law and one walk of the town for all of it: the checker pays for every
# multiplication it reduces, so three laws would walk the town three times.
# The split makes streets, gangs and dead ends; a dead end is between one in
# twenty and one in four of the junctions; and no cut leaves a half narrower
# than nine metres.
law the_split_has_every_kind_of_cut_a_fair_share_of_dead_ends_and_no_sliver:
  { T.split_holds(T.town_cuts(T.seed_of_town())) == True{} : Bool }

def the_split_has_every_kind_of_cut_a_fair_share_of_dead_ends_and_no_sliver():
  {==}
