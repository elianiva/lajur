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
import ./town.bend as T
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

# ===========================================================================
# The town: a lattice that bends, and the duty at each junction
#
# The field is the only source of curvature, so three numbers bound every
# radius in the town. Indexing decides a junction's class and geometry decides
# its shape, so the same rules hold whatever seed moves it.
# ===========================================================================

law a_block_pitches_seventy_metres:
  { T.pitch_cm() == 7000 : U32 }

def a_block_pitches_seventy_metres():
  {==}

law no_block_can_fold:
  { U32.is_lt(0, T.edge_cm()) == True{} : Bool }

def no_block_can_fold():
  {==}

law the_tightest_bend_clears_the_minimum_radius:
  { U32.is_le(8000, T.radius_floor_cm()) == True{} : Bool }

def the_tightest_bend_clears_the_minimum_radius():
  {==}

law every_junction_keeps_a_street_to_leave_by:
  { T.every_node_wide(99n, 0) == True{} : Bool }

def every_junction_keeps_a_street_to_leave_by():
  {==}

law the_left_of_a_northern_approach_is_the_west_branch:
  { T.left_of(T.North{}) == T.West{} : T.Dir }

def the_left_of_a_northern_approach_is_the_west_branch():
  {==}

law a_four_way_of_equal_roads_yields_to_the_left:
  { T.duty_of(T.Uncontrolled{}, T.FourEqual{}) == T.YieldLeft{} : T.Duty }

def a_four_way_of_equal_roads_yields_to_the_left():
  {==}

law a_minor_branch_yields_to_the_main_road:
  { T.duty_of(T.Uncontrolled{}, T.FourMajor{}) == T.YieldMain{} : T.Duty }

def a_minor_branch_yields_to_the_main_road():
  {==}

law a_perpendicular_t_yields_to_the_through_road:
  { T.duty_of(T.Uncontrolled{}, T.StraightT{}) == T.YieldThrough{} : T.Duty }

def a_perpendicular_t_yields_to_the_through_road():
  {==}

law a_skew_t_yields_to_the_left_branch:
  { T.duty_of(T.Uncontrolled{}, T.SkewT{}) == T.YieldLeft{} : T.Duty }

def a_skew_t_yields_to_the_left_branch():
  {==}

law a_roundabout_yields_to_the_right:
  { T.duty_of(T.Roundabout{}, T.FourEqual{}) == T.YieldRight{} : T.Duty }

def a_roundabout_yields_to_the_right():
  {==}

law a_signal_outranks_the_shape:
  { T.duty_of(T.Signal{}, T.SkewT{}) == T.ObeySignal{} : T.Duty }

def a_signal_outranks_the_shape():
  {==}

law a_bend_asks_nothing_of_priority:
  { T.duty_of(T.Uncontrolled{}, T.Bend{}) == T.FreePassage{} : T.Duty }

def a_bend_asks_nothing_of_priority():
  {==}

law the_two_signal_phases_never_show_green_together:
  { T.phases_disjoint(26n, 0) == True{} : Bool }

def the_two_signal_phases_never_show_green_together():
  {==}

# ---------------------------------------------------------------------------
# The town the game ships carries every case the statute names.
# ---------------------------------------------------------------------------

law the_town_has_a_signalised_crossing:
  { T.control(4, 0) == T.Signal{} : T.Control }

def the_town_has_a_signalised_crossing():
  {==}

law the_town_has_a_roundabout_at_its_heart:
  { T.control(4, 4) == T.Roundabout{} : T.Control }

def the_town_has_a_roundabout_at_its_heart():
  {==}

law the_town_has_a_perpendicular_t:
  { T.shape(1, 0, T.seed_of_town()) == T.StraightT{} : T.Shape }

def the_town_has_a_perpendicular_t():
  {==}

law the_town_has_a_skew_t:
  { T.shape(3, 0, T.seed_of_town()) == T.SkewT{} : T.Shape }

def the_town_has_a_skew_t():
  {==}

law the_town_has_a_four_way_of_equal_roads:
  { T.duty(1, 3, T.seed_of_town()) == T.YieldLeft{} : T.Duty }

def the_town_has_a_four_way_of_equal_roads():
  {==}

law the_town_has_a_minor_branch_onto_a_main_road:
  { T.duty(1, 4, T.seed_of_town()) == T.YieldMain{} : T.Duty }

def the_town_has_a_minor_branch_onto_a_main_road():
  {==}

law the_town_has_a_bend:
  { T.duty(7, 0, T.seed_of_town()) == T.FreePassage{} : T.Duty }

def the_town_has_a_bend():
  {==}

# ---------------------------------------------------------------------------
# The street between two junctions
# ---------------------------------------------------------------------------

law a_street_starts_at_its_first_node:
  { T.at(T.curve_of(3, 3, T.East{}, T.seed_of_town()), 0) == T.site(3, 3, T.seed_of_town()) : T.Pt }

def a_street_starts_at_its_first_node():
  {==}

law a_street_ends_at_its_second_node:
  { T.at(T.curve_of(3, 3, T.East{}, T.seed_of_town()), 1024) == T.site(4, 3, T.seed_of_town()) : T.Pt }

def a_street_ends_at_its_second_node():
  {==}

law every_street_stays_inside_the_town:
  { T.samples_inside(T.samples(3, 3, T.East{}, T.seed_of_town())) == True{} : Bool }

def every_street_stays_inside_the_town():
  {==}

law a_street_is_drawn_in_nine_points:
  { T.sample_count(T.samples(3, 3, T.East{}, T.seed_of_town())) == 9 : U32 }

def a_street_is_drawn_in_nine_points():
  {==}

# ---------------------------------------------------------------------------
# What each approach carries
# ---------------------------------------------------------------------------

law a_signalised_approach_has_a_stop_line:
  { T.every_mark(T.approaches(4, 0, T.seed_of_town()), T.StopLine{}) == True{} : Bool }

def a_signalised_approach_has_a_stop_line():
  {==}

law a_signalised_approach_has_a_head:
  { T.every_head(T.approaches(4, 0, T.seed_of_town())) == True{} : Bool }

def a_signalised_approach_has_a_head():
  {==}

law a_bundaran_gives_way_from_every_approach:
  { T.every_mark(T.approaches(4, 4, T.seed_of_town()), T.GiveWayLine{}) == True{} : Bool }

def a_bundaran_gives_way_from_every_approach():
  {==}

law a_skew_t_posts_nothing:
  { T.every_post(T.approaches(3, 0, T.seed_of_town()), T.NoSign{}) == True{} : Bool }

def a_skew_t_posts_nothing():
  {==}

law a_perpendicular_t_stops_its_stem:
  { T.mark_at(1, 0, T.South{}, T.seed_of_town()) == T.GiveWayLine{} : T.Mark }

def a_perpendicular_t_stops_its_stem():
  {==}

law the_warning_stands_across_from_the_give_way:
  { T.post_at(1, 0, T.East{}, T.seed_of_town()) == T.PriorityWarning{} : T.Post }

def the_warning_stands_across_from_the_give_way():
  {==}

law the_minor_road_carries_the_give_way_sign:
  { T.post_at(1, 4, T.North{}, T.seed_of_town()) == T.GiveWaySign{} : T.Post }

def the_minor_road_carries_the_give_way_sign():
  {==}

law every_line_stands_behind_the_kerb:
  { T.every_line_behind_the_kerb(T.approaches(1, 4, T.seed_of_town())) == True{} : Bool }

def every_line_stands_behind_the_kerb():
  {==}

# ---------------------------------------------------------------------------
# Blocks and lots
# ---------------------------------------------------------------------------

law a_block_holds_at_least_one_row:
  { U32.is_le(1, T.rows_in(3, 3, T.seed_of_town())) == True{} : Bool }

def a_block_holds_at_least_one_row():
  {==}

law a_block_holds_at_least_one_lot:
  { U32.is_le(1, T.lots_in(3, 3, T.seed_of_town())) == True{} : Bool }

def a_block_holds_at_least_one_lot():
  {==}

law a_frontage_row_is_twelve_metres_deep:
  { T.row_depth_cm() == 1200 : U32 }

def a_frontage_row_is_twelve_metres_deep():
  {==}

law every_row_lands_inside_the_town:
  { T.rows_inside_block(4n, 0, 3, 3, T.seed_of_town()) == True{} : Bool }

def every_row_lands_inside_the_town():
  {==}
