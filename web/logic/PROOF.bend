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
import ./world.bend as W
import ./lokal.bend as L
import ../../bend/model.bend as M
import ../../bend/rules.bend as R

# ===========================================================================
# The route: the world's own roads, one leg at a time
# ===========================================================================

# At a crossing, or a junction of lokal streets, the route takes a road that
# is there, and takes the turn the driver signalled whenever that road is
# there; it turns back only when no other road leaves. The law walks every exit a crossing can offer, open or
# closed, for every turn.
law the_route_takes_only_roads_that_are_there:
  { G.every_exit_holds() == True{} : Bool }

def the_route_takes_only_roads_that_are_there():
  {==}

# The lattice keeps its crossings at least 230 m apart and a tick at the fastest
# limit covers under a metre, so one tick passes one crossing at most.
law a_tick_cannot_pass_two_crossings:
  { U32.is_lt(G.roll(G.fastest()), G.shortest_leg()) == True{} : Bool }

def a_tick_cannot_pass_two_crossings():
  {==}

law a_leg_holds_until_its_end:
  { G.walked(G.Leg{1, 0, 1, 50000}, 40000, 20261024, 1) == (G.Leg{1, 0, 1, 50000}, 40000) : G.Leg & U32 }

def a_leg_holds_until_its_end():
  {==}

# A tap of the indicator chooses the turn only in the last hundred metres
# before a crossing; further back it is a lane change, and the car keeps to
# its road.
law only_the_last_hundred_metres_choose_a_turn:
  { Bool.and(
      U32.is_eq(G.turn_after(G.near_crossing(G.Leg{1, 0, 1, 50000}, 39000),
                             G.Controls{False{}, False{}, False{}, False{}},
                             G.Controls{True{}, False{}, False{}, False{}}, 1), 1),
      U32.is_eq(G.turn_after(G.near_crossing(G.Leg{1, 0, 1, 50000}, 41000),
                             G.Controls{False{}, False{}, False{}, False{}},
                             G.Controls{True{}, False{}, False{}, False{}}, 1), 0)) == True{} : Bool }

def only_the_last_hundred_metres_choose_a_turn():
  {==}

# The first road of every drive is there, and it is an arterial.
law the_drive_starts_on_an_arterial_that_is_there:
  { Bool.and(G.open_road(G.start_seed(), 1, 0, 1), U32.is_eq(W.class_code(G.class_on(G.start_leg())), 1)) == True{} : Bool }

def the_drive_starts_on_an_arterial_that_is_there():
  {==}

# A collector or a lokal street has one lane each way. On one, a tap of the
# indicator starts no lane change, and the car keeps to the kerb lane from
# any lane it arrives in.
law a_one_lane_road_keeps_the_car_in_the_kerb_lane:
  for l: G.Lane
  { G.lane_of(G.player_next(G.Player{l, 1000, G.Off{}, 0, 0, l},
      G.Controls{False{}, False{}, False{}, False{}},
      G.Controls{False{}, True{}, False{}, False{}}, False{})) == G.Outer{} : G.Lane }

def a_one_lane_road_keeps_the_car_in_the_kerb_lane(l):
  match l:
    case G.Inner{}:
      {==}
    case G.Outer{}:
      {==}

# PM 111/2015 Pasal 3 ayat (4): a lokal street is a residential road, 30 km/h,
# whatever main road the car turned in from.
law a_lokal_street_is_thirty:
  { U32.is_eq(G.kmh(G.limit_of(G.zone_at(True{}, G.Leg{1, 0, 1, 50000}))), 30) == True{} : Bool }

def a_lokal_street_is_thirty():
  {==}

# A tap arms a door on its own side only, and only within sixty metres.
law a_door_arms_on_its_side_within_sixty_metres:
  { Bool.and(U32.is_eq(G.door_ahead([L.Door{9000, True{}, 0, 0, 0, W.Pt{0, 0}}], True{}, 4000, G.no_door()), 9000),
    Bool.and(U32.is_eq(G.door_ahead([L.Door{9000, True{}, 0, 0, 0, W.Pt{0, 0}}], False{}, 4000, G.no_door()), G.no_door()),
             U32.is_eq(G.door_ahead([L.Door{9000, True{}, 0, 0, 0, W.Pt{0, 0}}], True{}, 2000, G.no_door()), G.no_door()))) == True{} : Bool }

def a_door_arms_on_its_side_within_sixty_metres():
  {==}

# Out of a lokal street with no signal, the car turns left onto the main
# road: in left-hand traffic, the turn that crosses no lane.
law out_of_a_lokal_street_unsignalled_is_a_left_turn:
  { G.pick_exit(1, True{}, False{}, True{}) == 0 : U32 }

def out_of_a_lokal_street_unsignalled_is_a_left_turn():
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

law a_lane_change_takes_twenty_four_ticks:
  { G.lane_change_ticks() == 24 : U32 }

def a_lane_change_takes_twenty_four_ticks():
  {==}

law the_indicator_outlasts_the_lane_change:
  { U32.is_lt(G.lane_change_ticks(), G.lamp_ticks()) == True{} : Bool }

def the_indicator_outlasts_the_lane_change():
  {==}

law a_lane_change_counts_down:
  { G.after_travel(G.travel(10, G.Inner{}, G.Outer{})) == 9 : U32 }

def a_lane_change_counts_down():
  {==}

law a_tick_in_motion_holds_the_old_lane:
  { G.arriving(G.travel(5, G.Inner{}, G.Outer{})) == G.Inner{} : G.Lane }

def a_tick_in_motion_holds_the_old_lane():
  {==}

law the_last_tick_arrives:
  { G.arriving(G.travel(1, G.Inner{}, G.Outer{})) == G.Outer{} : G.Lane }

def the_last_tick_arrives():
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

law the_throttle_stops_at_the_fastest_legal_speed:
  { G.speed_next(G.fastest(), True{}, False{}) == G.fastest() : U32 }

def the_throttle_stops_at_the_fastest_legal_speed():
  {==}

law the_fastest_legal_speed_is_one_hundred:
  { G.kmh(G.fastest()) == 100 : U32 }

def the_fastest_legal_speed_is_one_hundred():
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

# Pasal 108 ayat (4): the start sits in the right lane because it is moving
# faster than the car beside it, and the same player outrun by that car is
# charged. The kerb lane asks nothing of the article.
# The zone the road is in sets both the ceiling the screen shows and the one the
# verdict applies, because both read the statute's table.
law the_verdict_reads_the_zone_the_road_is_in:
  for z: M.Zone
  { R.contains(21, R.charges(G.scenario_in(G.cruising(U32.add(G.limit_of(z), 100)), z))) == True{} : Bool }

def the_verdict_reads_the_zone_the_road_is_in(z):
  match z:
    case M.Residential{}:
      {==}
    case M.Urban{}:
      {==}
    case M.Intercity{}:
      {==}
    case M.Motorway{}:
      {==}

law the_ceiling_is_lawful_in_every_zone:
  for z: M.Zone
  { R.contains(21, R.charges(G.scenario_in(G.cruising(G.limit_of(z)), z))) == False{} : Bool }

def the_ceiling_is_lawful_in_every_zone(z):
  match z:
    case M.Residential{}:
      {==}
    case M.Urban{}:
      {==}
    case M.Intercity{}:
      {==}
    case M.Motorway{}:
      {==}

law the_start_holds_the_right_lane_lawfully:
  { R.contains(52, R.charges(G.scenario_among(G.player_of(G.start()), G.traffic_of(G.start()), G.zone_of(G.start()), False{}))) == False{} : Bool }

def the_start_holds_the_right_lane_lawfully():
  {==}

law a_slow_player_in_the_right_lane_is_charged:
  { R.contains(52, R.charges(G.scenario_among(G.cruising(1000),
      [ G.Car{1, G.Outer{}, 3000, 1400, G.Sedan{}, 0} ], M.Urban{}, False{}))) == True{} : Bool }

def a_slow_player_in_the_right_lane_is_charged():
  {==}

# Pasal 310 ayat (1): the drive's crash is a charged collision, not a silent
# stop, and the panel can cite it.
law a_crash_is_charged_under_pasal_310:
  { R.contains(59, R.charges(G.scenario_crash(G.cruising(1000), True{}))) == True{} : Bool }

def a_crash_is_charged_under_pasal_310():
  {==}

law a_clean_moment_cites_no_collision:
  { R.contains(59, R.charges(G.scenario_crash(G.cruising(1000), False{}))) == False{} : Bool }

def a_clean_moment_cites_no_collision():
  {==}

law the_kerb_lane_asks_nothing_of_pasal_108:
  { G.spread(R.charges(G.scenario_among(G.Player{G.Outer{}, 1000, G.Off{}, 0, 0, G.Outer{}},
      [ G.Car{1, G.Inner{}, 3000, 1400, G.Sedan{}, 0} ], M.Urban{}, False{}))) == Nil{} : List<&2, U32> }

def the_kerb_lane_asks_nothing_of_pasal_108():
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

law a_block_pitches_a_hundred_and_forty_metres:
  { T.pitch_cm() == 14000 : U32 }

def a_block_pitches_a_hundred_and_forty_metres():
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
  { T.every_node_wide(30n, 0) == True{} : Bool }

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
  { T.control(2, 0) == T.Signal{} : T.Control }

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

# At a 140 m pitch the field's Ts come out square to the through road, and the
# town itself has no skew T. The rule still classifies one, which is what the
# verdict text promises: a T on a bend is a skew T.
law a_t_on_a_bend_is_a_skew_t:
  { T.shape_of(3, False{}, False{}) == T.SkewT{} : T.Shape }

def a_t_on_a_bend_is_a_skew_t():
  {==}

law the_town_has_a_four_way_of_equal_roads:
  { T.duty(1, 1, T.seed_of_town()) == T.YieldLeft{} : T.Duty }

def the_town_has_a_four_way_of_equal_roads():
  {==}

law the_town_has_a_minor_branch_onto_a_main_road:
  { T.duty(1, 2, T.seed_of_town()) == T.YieldMain{} : T.Duty }

def the_town_has_a_minor_branch_onto_a_main_road():
  {==}

law the_town_has_a_bend:
  { T.duty(0, 0, T.seed_of_town()) == T.FreePassage{} : T.Duty }

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
  { T.every_mark(T.approaches(2, 0, T.seed_of_town()), T.StopLine{}) == True{} : Bool }

def a_signalised_approach_has_a_stop_line():
  {==}

law a_signalised_approach_has_a_head:
  { T.every_head(T.approaches(2, 0, T.seed_of_town())) == True{} : Bool }

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
  { T.every_line_behind_the_box(T.approaches(1, 4, T.seed_of_town()), 1, 4) == True{} : Bool }

def every_line_stands_behind_the_kerb():
  {==}

# ---------------------------------------------------------------------------
# The junction box
#
# A street stops short of the node, and the ground between the stops is the
# junction. The kerb return is what rounds that ground, and these laws hold it
# to the band Bina Marga 08/PBM/2024 gives and hold every line behind it.
# ---------------------------------------------------------------------------

law a_kerb_return_clears_six_metres:
  { U32.is_le(600, T.junction_radius_cm(3, 3, T.seed_of_town())) == True{} : Bool }

def a_kerb_return_clears_six_metres():
  {==}

law a_kerb_return_stays_inside_its_band:
  { U32.is_le(T.junction_radius_cm(0, 0, T.seed_of_town()), 1200) == True{} : Bool }

def a_kerb_return_stays_inside_its_band():
  {==}

law a_kerb_return_moves_with_the_class:
  { T.junction_rank(0, 0) == 2 : U32 }

def a_kerb_return_moves_with_the_class():
  {==}

law a_mouth_clears_the_street_across_it:
  { U32.is_le(T.cross_half(1, 4, T.North{}), T.mouth_cm(1, 4, T.North{}, T.seed_of_town())) == True{} : Bool }

def a_mouth_clears_the_street_across_it():
  {==}

law a_line_stands_behind_the_box:
  { U32.is_le(T.mouth_cm(1, 4, T.North{}, T.seed_of_town()),
              T.line_at(1, 4, T.North{}, T.seed_of_town())) == True{} : Bool }

def a_line_stands_behind_the_box():
  {==}

# ---------------------------------------------------------------------------
# A building fits its lot
#
# A lot's front line is the street's own curve pushed back by the kerb and the
# pavement, cut by the fraction of the street it takes. The building is drawn
# to that lot and no bigger, so a building can only collide with another if a
# lot is narrower than the building standing in it. These laws rule that out
# twice: from the three numbers that bound the lattice, and over every roll the
# kind picker can see.
# ---------------------------------------------------------------------------

law a_block_holds_at_least_one_ring:
  { U32.is_le(1, T.rings_in(1, 1, T.seed_of_town())) == True{} : Bool }

def a_block_holds_at_least_one_ring():
  {==}

# The mitre sends a row short of a corner by its band times cot(theta/2), and
# the constant that stands for that is only honest while no corner is sharper
# than fifty-eight degrees. This is the field's own corners, every one of them,
# checked against that sine rather than assumed to clear it.
law every_block_corner_stays_near_square:
  { T.every_block_corner(30n, 0, T.seed_of_town()) == True{} : Bool }

def every_block_corner_stays_near_square():
  {==}

law a_core_tiles_its_own_ground:
  { Bool.and(T.core_edges_rise(8n, 0, 1, 1, True{}, T.seed_of_town()),
             T.core_edges_rise(8n, 0, 1, 1, False{}, T.seed_of_town())) == True{} : Bool }

def a_core_tiles_its_own_ground():
  {==}

law every_frontage_holds_a_lot_inside_the_town:
  { T.sides_inside(2n, 0, 1, 1, T.seed_of_town()) == True{} : Bool }

def every_frontage_holds_a_lot_inside_the_town():
  {==}

law a_frontage_row_is_thirteen_metres_deep:
  { T.row_depth_cm() == 1300 : U32 }

def a_frontage_row_is_thirteen_metres_deep():
  {==}

law a_frontage_starts_behind_the_box:
  { U32.is_le(T.mouth_cm(1, 1, T.East{}, T.seed_of_town()),
              T.side_len(1, 1, 0, T.seed_of_town())) == True{} : Bool }

def a_frontage_starts_behind_the_box():
  {==}

law a_lot_is_never_narrower_than_its_pitch:
  { U32.is_le(T.pitch_of(0), T.lot_width(1, 1, 0, 0, T.seed_of_town())) == True{} : Bool }

def a_lot_is_never_narrower_than_its_pitch():
  {==}

law a_frontage_lot_holds_a_shop_house:
  { U32.is_le(T.kind_min_cm(T.Ruko{}), T.pitch_of(0)) == True{} : Bool }

def a_frontage_lot_holds_a_shop_house():
  {==}

law a_frontage_lot_holds_a_warung:
  { U32.is_le(T.kind_min_cm(T.Warung{}), T.pitch_of(0)) == True{} : Bool }

def a_frontage_lot_holds_a_warung():
  {==}

law a_rear_lot_holds_a_house:
  { U32.is_le(T.kind_min_cm(T.House{}), T.pitch_of(1)) == True{} : Bool }

def a_rear_lot_holds_a_house():
  {==}

law a_rear_lot_holds_a_kos:
  { U32.is_le(T.kind_min_cm(T.Kos{}), T.pitch_of(1)) == True{} : Bool }

def a_rear_lot_holds_a_kos():
  {==}

law a_rear_lot_holds_a_terrace:
  { U32.is_le(T.kind_min_cm(T.Petak{}), T.pitch_of(1)) == True{} : Bool }

def a_rear_lot_holds_a_terrace():
  {==}

law no_building_outgrows_its_ring:
  { Bool.and(U32.is_le(T.kind_depth_cm(T.Ruko{}), T.row_depth_cm()),
    Bool.and(U32.is_le(T.kind_depth_cm(T.Warung{}), T.row_depth_cm()),
    Bool.and(U32.is_le(T.kind_depth_cm(T.House{}), T.row_depth_cm()),
    Bool.and(U32.is_le(T.kind_depth_cm(T.Kos{}), T.row_depth_cm()),
    Bool.and(U32.is_le(T.kind_depth_cm(T.Petak{}), T.row_depth_cm()),
    Bool.and(U32.is_le(T.kind_depth_cm(T.Filler{}), T.row_depth_cm()),
    Bool.and(U32.is_le(T.kind_depth_cm(T.Minimarket{}), T.row_depth_cm()),
    Bool.and(U32.is_le(T.kind_depth_cm(T.Bengkel{}), T.row_depth_cm()),
             U32.is_le(T.kind_depth_cm(T.Gudang{}), T.row_depth_cm()))))))))) == True{} : Bool }

def no_building_outgrows_its_ring():
  {==}

law every_kind_fits_the_lot_it_is_chosen_for:
  { Bool.and(T.every_roll_fits(100n, 0, True{}, T.pitch_of(0)),
             T.every_roll_fits(100n, 0, False{}, T.pitch_of(1))) == True{} : Bool }

def every_kind_fits_the_lot_it_is_chosen_for():
  {==}

law every_lot_of_a_block_holds_a_building_that_fits:
  { Bool.and(T.lots_fit(2n, 0, 0, 0, 1, 1, T.seed_of_town()),
             T.lots_fit(2n, 0, 1, 1, 1, 1, T.seed_of_town())) == True{} : Bool }

def every_lot_of_a_block_holds_a_building_that_fits():
  {==}

# ---------------------------------------------------------------------------
# A prop fits its pavement
#
# One prop stands in front of every frontage lot, on the lot's own centre line,
# so two props are a lot apart. A lot holds two of the widest crown, so no two
# crowns meet, and the prop line is between the kerb and the buildings.
# ---------------------------------------------------------------------------

law no_two_crowns_meet:
  { U32.is_le(U32.mul(2, T.widest_crown_cm()), T.pitch_of(0)) == True{} : Bool }

def no_two_crowns_meet():
  {==}

law a_prop_stands_on_the_pavement:
  { Bool.and(T.prop_on_pavement(1, 1, 0), Bool.and(T.prop_on_pavement(1, 1, 1),
             Bool.and(T.prop_on_pavement(1, 1, 2), T.prop_on_pavement(1, 1, 3)))) == True{} : Bool }

def a_prop_stands_on_the_pavement():
  {==}

law the_props_of_a_frontage_keep_apart:
  { T.props_apart(2n, 0, 1, 1, 0, T.seed_of_town()) == True{} : Bool }

def the_props_of_a_frontage_keep_apart():
  {==}

law a_pole_spans_forty_metres:
  { U32.is_le(4000, U32.mul(7, T.pitch_of(0))) == True{} : Bool }

def a_pole_spans_forty_metres():
  {==}

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
