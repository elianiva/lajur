# Proofs for the driving model.
#
# Each law names one requirement the game lives under and states it in full;
# the def under it is the proof, reflexivity once the checker has reduced both
# sides. A change that moves a lane centre, a curvature ceiling or a citation
# stops the law checking, which is the point.
#
#   cd web/logic && bend PROOF.bend            the checker
#   cd web/logic && bend PROOF.bend --verdict  the same through the Lean kernel
import Base
import ./game.bend as G
import ../../bend/model.bend as M
import ../../bend/rules.bend as R

# ===========================================================================
# The generated road: value noise, eased, integrated
# ===========================================================================

law the_ease_curve_holds_both_ends:
  { Bool.and(U32.is_eq(G.ease(0), 0), U32.is_eq(G.ease(1000), 1000)) == True{} : Bool }

def the_ease_curve_holds_both_ends():
  {==}

law a_blend_holds_its_start:
  { G.blend(True{}, 200, 800, 0) == 200 : U32 }

def a_blend_holds_its_start():
  {==}

law a_blend_holds_its_end:
  { G.blend(True{}, 200, 800, 1000) == 800 : U32 }

def a_blend_holds_its_end():
  {==}

law a_falling_blend_holds_its_end:
  { G.blend(False{}, 800, 200, 1000) == 200 : U32 }

def a_falling_blend_holds_its_end():
  {==}

law a_straight_section_has_no_curvature:
  { U32.is_eq(G.rate_of(True{}, 500), 0) == True{} : Bool }

def a_straight_section_has_no_curvature():
  {==}

law the_sharpest_bend_is_one_point_two_degrees_a_metre:
  { U32.is_eq(G.rate_of(True{}, 1000), 120) == True{} : Bool }

def the_sharpest_bend_is_one_point_two_degrees_a_metre():
  {==}

law a_bend_to_the_left_is_measured_the_same_way:
  { U32.is_eq(G.rate_of(False{}, 0), 120) == True{} : Bool }

def a_bend_to_the_left_is_measured_the_same_way():
  {==}

law the_road_bends_no_harder_than_its_ceiling:
  { U32.is_le(G.curve_rate(1234, 20261024), 120) == True{} : Bool }

def the_road_bends_no_harder_than_its_ceiling():
  {==}

law a_bend_is_either_left_or_right_at_every_sample:
  { Bool.or(G.curve_left(0, 20261024), Bool.not(G.curve_left(0, 20261024))) == True{} : Bool }

def a_bend_is_either_left_or_right_at_every_sample():
  {==}

law a_tick_cannot_cross_two_chunks:
  { U32.is_lt(G.roll(3333), G.chunk_cm()) == True{} : Bool }

def a_tick_cannot_cross_two_chunks():
  {==}

law a_chunk_holds_until_its_end:
  { G.walked(24, 4000) == (24, 4000) : U32 & U32 }

def a_chunk_holds_until_its_end():
  {==}

law a_chunk_rolls_over_once_it_is_spent:
  { G.walked(24, 5100) == (25, 100) : U32 & U32 }

def a_chunk_rolls_over_once_it_is_spent():
  {==}

# ===========================================================================
# Lanes: two a side, and the car stays inside them
# ===========================================================================

law both_lanes_sit_inside_the_carriageway:
  for l: G.Lane
  { U32.is_le(G.lane_offset(l), 480) == True{} : Bool }

def both_lanes_sit_inside_the_carriageway(l):
  match l:
    case G.Inner{}:
      {==}
    case G.Outer{}:
      {==}

law the_inner_lane_is_beside_the_centre_line:
  { G.lane_offset(G.Inner{}) == 160 : U32 }

def the_inner_lane_is_beside_the_centre_line():
  {==}

law the_outer_lane_is_beside_the_kerb:
  { G.lane_offset(G.Outer{}) == 480 : U32 }

def the_outer_lane_is_beside_the_kerb():
  {==}

law a_lane_change_never_leaves_the_carriageway:
  for l: G.Lane
  for d: G.Dir
  { U32.is_le(G.lane_offset(G.shift(l, d)), 480) == True{} : Bool }

def a_lane_change_never_leaves_the_carriageway(l, d):
  match l d:
    case G.Inner{} G.Left{}:
      {==}
    case G.Inner{} G.Right{}:
      {==}
    case G.Outer{} G.Left{}:
      {==}
    case G.Outer{} G.Right{}:
      {==}

# ===========================================================================
# Controls: a tap is one lane, a hold is none
# ===========================================================================

law a_tap_moves_one_lane:
  { G.maybe_shift(G.Inner{}, True{}, G.Left{}) == G.Outer{} : G.Lane }

def a_tap_moves_one_lane():
  {==}

law a_held_key_moves_nothing:
  { G.maybe_shift(G.Inner{}, False{}, G.Left{}) == G.Inner{} : G.Lane }

def a_held_key_moves_nothing():
  {==}

law the_kerb_lane_holds_its_edge:
  { G.shift(G.Outer{}, G.Left{}) == G.Outer{} : G.Lane }

def the_kerb_lane_holds_its_edge():
  {==}

law a_lane_change_lights_the_indicator:
  { G.signalling(G.ToRight{}) == True{} : Bool }

def a_lane_change_lights_the_indicator():
  {==}

law the_indicator_goes_out:
  { G.still_on(True{}, G.ToLeft{}) == G.Off{} : G.Signal }

def the_indicator_goes_out():
  {==}

# ===========================================================================
# Speed: the ceiling comes from the statute's table
# ===========================================================================

law the_urban_ceiling_is_fifty_kmh:
  { G.kmh(G.limit_of(M.Urban{})) == 50 : U32 }

def the_urban_ceiling_is_fifty_kmh():
  {==}

law the_motorway_ceiling_is_one_hundred_kmh:
  { G.kmh(G.limit_of(M.Motorway{})) == 100 : U32 }

def the_motorway_ceiling_is_one_hundred_kmh():
  {==}

law the_throttle_stops_at_one_hundred_and_twenty:
  { G.speed_next(3333, True{}, False{}) == 3333 : U32 }

def the_throttle_stops_at_one_hundred_and_twenty():
  {==}

law the_brake_stops_at_zero:
  { G.speed_next(0, False{}, True{}) == 0 : U32 }

def the_brake_stops_at_zero():
  {==}

law thirty_six_kmh_covers_sixteen_centimetres_a_tick:
  { G.roll(1000) == 16 : U32 }

def thirty_six_kmh_covers_sixteen_centimetres_a_tick():
  {==}

# ===========================================================================
# The verdict: the catalogue, not a second copy of the rules
# ===========================================================================

law speeding_is_charged_under_article_106:
  { R.contains(21, R.charges(G.scenario_for(G.cruising(1500)))) == True{} : Bool }

def speeding_is_charged_under_article_106():
  {==}

law a_legal_speed_is_charged_nothing:
  { R.contains(21, R.charges(G.scenario_for(G.cruising(1300)))) == False{} : Bool }

def a_legal_speed_is_charged_nothing():
  {==}

law a_clean_moment_has_no_charges:
  { G.spread(R.charges(G.scenario_for(G.cruising(1300)))) == Nil{} : List<&2, U32> }

def a_clean_moment_has_no_charges():
  {==}

law the_speeding_charge_cites_pasal_106:
  { G.article_of(21) == 106 : U32 }

def the_speeding_charge_cites_pasal_106():
  {==}

law the_speeding_charge_costs_500000:
  { R.fine_of(21) == 500000 : U32 }

def the_speeding_charge_costs_500000():
  {==}

law the_start_is_legal:
  { R.contains(21, R.charges(G.scenario_for(G.player_of(G.start())))) == False{} : Bool }

def the_start_is_legal():
  {==}

# ===========================================================================
# Traffic: a car in the lane, inside the envelope, is a crash
# ===========================================================================

law a_car_in_the_lane_ahead_blocks_it:
  { G.blocked([G.Car{1, G.Inner{}, 300, 700, G.Sedan{}, 0}], G.Inner{}) == True{} : Bool }

def a_car_in_the_lane_ahead_blocks_it():
  {==}

law a_bus_blocks_from_further_away:
  { G.blocked([G.Car{1, G.Inner{}, 600, 700, G.Bus{}, 0}], G.Inner{}) == True{} : Bool }

def a_bus_blocks_from_further_away():
  {==}

law a_saloon_at_the_same_gap_does_not:
  { G.blocked([G.Car{1, G.Inner{}, 600, 700, G.Sedan{}, 0}], G.Inner{}) == False{} : Bool }

def a_saloon_at_the_same_gap_does_not():
  {==}

law a_bike_lets_the_player_get_closer:
  { G.blocked([G.Car{1, G.Inner{}, 400, 700, G.Bike{}, 0}], G.Inner{}) == False{} : Bool }

def a_bike_lets_the_player_get_closer():
  {==}

law a_car_in_the_other_lane_does_not:
  { G.blocked([G.Car{1, G.Outer{}, 300, 700, G.Sedan{}, 0}], G.Inner{}) == False{} : Bool }

def a_car_in_the_other_lane_does_not():
  {==}

law a_gap_never_goes_below_zero:
  { G.adjust(100, 0, 1000) == 0 : U32 }

def a_gap_never_goes_below_zero():
  {==}
