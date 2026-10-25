# Proofs for the world: the endless lattice the lab draws, cell by cell.
#
# Kept apart from PROOF.bend because these pass the Lean kernel as well as
# Bend's checker, and CI runs them through both; some of the town's laws run
# the kernel out of fuel.
#
#   cd web/logic && bend PROOF_WORLD.bend            the checker
#   cd web/logic && bend PROOF_WORLD.bend --verdict  the same through the Lean kernel
import Base
import ./world.bend as W

# ===========================================================================
# The world: an endless lattice of main roads, made one cell at a time
#
# These hold for every seed. Each decision below takes a handful of values, so
# a law walks every value the hash can roll rather than one seed's rolls.
# ===========================================================================

# A main road may bend at a crossing, but it never ends there. A crossing with
# both indices even may drop one of its four roads, and its neighbours never
# can; the law tries every drop a crossing and its four neighbours may make,
# for each parity a crossing can have.
law every_crossing_keeps_two_of_its_roads:
  { W.every_crossing_keeps_two() == True{} : Bool }

def every_crossing_keeps_two_of_its_roads():
  {==}

# Two collectors that meet a main road from either side meet it at one
# crossing, or stand at least a fifth of the road apart: never a dog-leg of a
# few metres. Every place a mouth can take is checked against its mirror.
law two_collectors_cross_or_stand_a_fifth_of_the_road_apart:
  { U32.is_ge(U32.mul(W.narrowest_stagger(), 5), 1024) == True{} : Bool }

def two_collectors_cross_or_stand_a_fifth_of_the_road_apart():
  {==}

# PM 111/2015 Pasal 3 ayat (4): a lokal street is a residential road, 30 km/h,
# and the arterials and collectors are urban roads, 50 km/h.
law a_lokal_street_is_thirty_and_a_main_road_fifty:
  { Bool.and(U32.is_eq(W.limit_of(W.Lokal{}), 30),
    Bool.and(U32.is_eq(W.limit_of(W.Collector{}), 50), U32.is_eq(W.limit_of(W.Arterial{}), 50))) == True{} : Bool }

def a_lokal_street_is_thirty_and_a_main_road_fifty():
  {==}

# Streets across a ring lane, a comb's teeth or a grid's, stand far enough
# apart for two rows of lots back to back, at every density the field can
# take.
law streets_across_a_lane_leave_two_rows_of_lots:
  { W.every_cross_gap_holds_lots() == True{} : Bool }

def streets_across_a_lane_leave_two_rows_of_lots():
  {==}

# Branches leave a street no nearer each other than the lokal floor, 20 m,
# at every density.
law branches_leave_a_street_at_least_twenty_metres_apart:
  { W.every_branch_gap_keeps_floor() == True{} : Bool }

def branches_leave_a_street_at_least_twenty_metres_apart():
  {==}
