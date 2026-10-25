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

# A lot, a prop and a tree stand only where they clear every cut. The test is
# the distance to the segment, and each end of the segment is measured from the
# end: a point beside the cut, past its end, near its end and on a slant.
law a_point_is_clear_of_a_cut_only_by_its_reach:
  { Bool.and(Bool.not(T.seg_clear(100, 100, T.Pt{0, 0}, T.Pt{1000, 0}, 300)),
    Bool.and(T.seg_clear(100, 500, T.Pt{0, 0}, T.Pt{1000, 0}, 300),
    Bool.and(Bool.not(T.seg_clear(1200, 0, T.Pt{0, 0}, T.Pt{1000, 0}, 300)),
    Bool.and(T.seg_clear(1400, 0, T.Pt{0, 0}, T.Pt{1000, 0}, 300),
    Bool.and(T.seg_clear(1000, 0, T.Pt{0, 0}, T.Pt{1000, 1000}, 500),
             Bool.not(T.seg_clear(600, 400, T.Pt{0, 0}, T.Pt{1000, 1000}, 300))))))) == True{} : Bool }

def a_point_is_clear_of_a_cut_only_by_its_reach():
  {==}
