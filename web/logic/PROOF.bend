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
import ./town/lattice.bend as Lat
import ./town/streets.bend as Str
import ./town/junction.bend as Jun
import ./town/blocks.bend as Blk
import ./town/pavement.bend as Pav
import ./town/split.bend as Spl
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
# limit covers under a metre, so one tick passes one crossing at most. A
# collector inside a cell meets a road only a third of the cell from either
# side, so its stretches are longer than a tick too.
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

# A collector inside a cell is a collector like the lattice's own: one lane
# each way and 50 km/h, whichever stretch of it the car is on.
law a_collector_inside_a_cell_is_fifty_with_one_lane:
  { Bool.and(Bool.not(G.wide_on(G.Cut{1, 1, 0, 65536, 28860})),
             U32.is_eq(G.kmh(G.limit_of(G.zone_on(G.Cut{1, 1, 0, 65536, 28860}))), 50)) == True{} : Bool }

def a_collector_inside_a_cell_is_fifty_with_one_lane():
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
  { Lat.pitch_cm() == 14000 : U32 }

def a_block_pitches_a_hundred_and_forty_metres():
  {==}

law no_block_can_fold:
  { U32.is_lt(0, Str.edge_cm()) == True{} : Bool }

def no_block_can_fold():
  {==}

law the_tightest_bend_clears_the_minimum_radius:
  { U32.is_le(8000, Str.radius_floor_cm()) == True{} : Bool }

def the_tightest_bend_clears_the_minimum_radius():
  {==}

law every_junction_keeps_a_street_to_leave_by:
  { Jun.every_node_wide(30n, 0) == True{} : Bool }

def every_junction_keeps_a_street_to_leave_by():
  {==}

law the_left_of_a_northern_approach_is_the_west_branch:
  { Str.left_of(Str.North{}) == Str.West{} : Str.Dir }

def the_left_of_a_northern_approach_is_the_west_branch():
  {==}

law a_four_way_of_equal_roads_yields_to_the_left:
  { Jun.duty_of(Jun.Uncontrolled{}, Jun.FourEqual{}) == Jun.YieldLeft{} : Jun.Duty }

def a_four_way_of_equal_roads_yields_to_the_left():
  {==}

law a_minor_branch_yields_to_the_main_road:
  { Jun.duty_of(Jun.Uncontrolled{}, Jun.FourMajor{}) == Jun.YieldMain{} : Jun.Duty }

def a_minor_branch_yields_to_the_main_road():
  {==}

law a_perpendicular_t_yields_to_the_through_road:
  { Jun.duty_of(Jun.Uncontrolled{}, Jun.StraightT{}) == Jun.YieldThrough{} : Jun.Duty }

def a_perpendicular_t_yields_to_the_through_road():
  {==}

law a_skew_t_yields_to_the_left_branch:
  { Jun.duty_of(Jun.Uncontrolled{}, Jun.SkewT{}) == Jun.YieldLeft{} : Jun.Duty }

def a_skew_t_yields_to_the_left_branch():
  {==}

law a_roundabout_yields_to_the_right:
  { Jun.duty_of(Jun.Roundabout{}, Jun.FourEqual{}) == Jun.YieldRight{} : Jun.Duty }

def a_roundabout_yields_to_the_right():
  {==}

law a_signal_outranks_the_shape:
  { Jun.duty_of(Jun.Signal{}, Jun.SkewT{}) == Jun.ObeySignal{} : Jun.Duty }

def a_signal_outranks_the_shape():
  {==}

law a_bend_asks_nothing_of_priority:
  { Jun.duty_of(Jun.Uncontrolled{}, Jun.Bend{}) == Jun.FreePassage{} : Jun.Duty }

def a_bend_asks_nothing_of_priority():
  {==}

law the_two_signal_phases_never_show_green_together:
  { Jun.phases_disjoint(26n, 0) == True{} : Bool }

def the_two_signal_phases_never_show_green_together():
  {==}

# ---------------------------------------------------------------------------
# The town the game ships carries every case the statute names.
# ---------------------------------------------------------------------------

law the_town_has_a_signalised_crossing:
  { Jun.control(2, 0) == Jun.Signal{} : Jun.Control }

def the_town_has_a_signalised_crossing():
  {==}

law the_town_has_a_roundabout_at_its_heart:
  { Jun.control(4, 4) == Jun.Roundabout{} : Jun.Control }

def the_town_has_a_roundabout_at_its_heart():
  {==}

law the_town_has_a_perpendicular_t:
  { Jun.shape(1, 0, Lat.seed_of_town()) == Jun.StraightT{} : Jun.Shape }

def the_town_has_a_perpendicular_t():
  {==}

# At a 140 m pitch the field's Ts come out square to the through road, and the
# town itself has no skew T. The rule still classifies one, which is what the
# verdict text promises: a T on a bend is a skew T.
law a_t_on_a_bend_is_a_skew_t:
  { Jun.shape_of(3, False{}, False{}) == Jun.SkewT{} : Jun.Shape }

def a_t_on_a_bend_is_a_skew_t():
  {==}

law the_town_has_a_four_way_of_equal_roads:
  { Jun.duty(1, 1, Lat.seed_of_town()) == Jun.YieldLeft{} : Jun.Duty }

def the_town_has_a_four_way_of_equal_roads():
  {==}

law the_town_has_a_minor_branch_onto_a_main_road:
  { Jun.duty(1, 2, Lat.seed_of_town()) == Jun.YieldMain{} : Jun.Duty }

def the_town_has_a_minor_branch_onto_a_main_road():
  {==}

law the_town_has_a_bend:
  { Jun.duty(0, 0, Lat.seed_of_town()) == Jun.FreePassage{} : Jun.Duty }

def the_town_has_a_bend():
  {==}

# ---------------------------------------------------------------------------
# The street between two junctions
# ---------------------------------------------------------------------------

law a_street_starts_at_its_first_node:
  { Str.at(Str.curve_of(3, 3, Str.East{}, Lat.seed_of_town()), 0) == Lat.site(3, 3, Lat.seed_of_town()) : Lat.Pt }

def a_street_starts_at_its_first_node():
  {==}

law a_street_ends_at_its_second_node:
  { Str.at(Str.curve_of(3, 3, Str.East{}, Lat.seed_of_town()), 1024) == Lat.site(4, 3, Lat.seed_of_town()) : Lat.Pt }

def a_street_ends_at_its_second_node():
  {==}

law every_street_stays_inside_the_town:
  { Str.samples_inside(Str.samples(3, 3, Str.East{}, Lat.seed_of_town())) == True{} : Bool }

def every_street_stays_inside_the_town():
  {==}

law a_street_is_drawn_in_nine_points:
  { Str.sample_count(Str.samples(3, 3, Str.East{}, Lat.seed_of_town())) == 9 : U32 }

def a_street_is_drawn_in_nine_points():
  {==}

# ---------------------------------------------------------------------------
# What each approach carries
# ---------------------------------------------------------------------------

law a_signalised_approach_has_a_stop_line:
  { Jun.every_mark(Jun.approaches(2, 0, Lat.seed_of_town()), Jun.StopLine{}) == True{} : Bool }

def a_signalised_approach_has_a_stop_line():
  {==}

law a_signalised_approach_has_a_head:
  { Jun.every_head(Jun.approaches(2, 0, Lat.seed_of_town())) == True{} : Bool }

def a_signalised_approach_has_a_head():
  {==}

law a_bundaran_gives_way_from_every_approach:
  { Jun.every_mark(Jun.approaches(4, 4, Lat.seed_of_town()), Jun.GiveWayLine{}) == True{} : Bool }

def a_bundaran_gives_way_from_every_approach():
  {==}

law a_skew_t_posts_nothing:
  { Jun.every_post(Jun.approaches(3, 0, Lat.seed_of_town()), Jun.NoSign{}) == True{} : Bool }

def a_skew_t_posts_nothing():
  {==}

law a_perpendicular_t_stops_its_stem:
  { Jun.mark_at(1, 0, Str.South{}, Lat.seed_of_town()) == Jun.GiveWayLine{} : Jun.Mark }

def a_perpendicular_t_stops_its_stem():
  {==}

law the_warning_stands_across_from_the_give_way:
  { Jun.post_at(1, 0, Str.East{}, Lat.seed_of_town()) == Jun.PriorityWarning{} : Jun.Post }

def the_warning_stands_across_from_the_give_way():
  {==}

law the_minor_road_carries_the_give_way_sign:
  { Jun.post_at(1, 4, Str.North{}, Lat.seed_of_town()) == Jun.GiveWaySign{} : Jun.Post }

def the_minor_road_carries_the_give_way_sign():
  {==}

law every_line_stands_behind_the_kerb:
  { Jun.every_line_behind_the_box(Jun.approaches(1, 4, Lat.seed_of_town()), 1, 4) == True{} : Bool }

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
  { U32.is_le(600, Jun.junction_radius_cm(3, 3, Lat.seed_of_town())) == True{} : Bool }

def a_kerb_return_clears_six_metres():
  {==}

law a_kerb_return_stays_inside_its_band:
  { U32.is_le(Jun.junction_radius_cm(0, 0, Lat.seed_of_town()), 1200) == True{} : Bool }

def a_kerb_return_stays_inside_its_band():
  {==}

law a_kerb_return_moves_with_the_class:
  { Jun.junction_rank(0, 0) == 2 : U32 }

def a_kerb_return_moves_with_the_class():
  {==}

law a_mouth_clears_the_street_across_it:
  { U32.is_le(Jun.cross_half(1, 4, Str.North{}), Jun.mouth_cm(1, 4, Str.North{}, Lat.seed_of_town())) == True{} : Bool }

def a_mouth_clears_the_street_across_it():
  {==}

law a_line_stands_behind_the_box:
  { U32.is_le(Jun.mouth_cm(1, 4, Str.North{}, Lat.seed_of_town()),
              Jun.line_at(1, 4, Str.North{}, Lat.seed_of_town())) == True{} : Bool }

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
  { U32.is_le(1, Blk.rings_in(1, 1, Lat.seed_of_town())) == True{} : Bool }

def a_block_holds_at_least_one_ring():
  {==}

# The mitre sends a row short of a corner by its band times cot(theta/2), and
# the constant that stands for that is only honest while no corner is sharper
# than fifty-eight degrees. This is the field's own corners, every one of them,
# checked against that sine rather than assumed to clear it.
law every_block_corner_stays_near_square:
  { Blk.every_block_corner(30n, 0, Lat.seed_of_town()) == True{} : Bool }

def every_block_corner_stays_near_square():
  {==}

law a_core_tiles_its_own_ground:
  { Bool.and(Blk.core_edges_rise(8n, 0, 1, 1, True{}, Lat.seed_of_town()),
             Blk.core_edges_rise(8n, 0, 1, 1, False{}, Lat.seed_of_town())) == True{} : Bool }

def a_core_tiles_its_own_ground():
  {==}

law every_frontage_holds_a_lot_inside_the_town:
  { Blk.sides_inside(2n, 0, 1, 1, Lat.seed_of_town()) == True{} : Bool }

def every_frontage_holds_a_lot_inside_the_town():
  {==}

law a_frontage_row_is_thirteen_metres_deep:
  { Blk.row_depth_cm() == 1300 : U32 }

def a_frontage_row_is_thirteen_metres_deep():
  {==}

law a_frontage_starts_behind_the_box:
  { U32.is_le(Jun.mouth_cm(1, 1, Str.East{}, Lat.seed_of_town()),
              Blk.side_len(1, 1, 0, Lat.seed_of_town())) == True{} : Bool }

def a_frontage_starts_behind_the_box():
  {==}

law a_lot_is_never_narrower_than_its_pitch:
  { U32.is_le(Blk.pitch_of(0), Blk.lot_width(1, 1, 0, 0, Lat.seed_of_town())) == True{} : Bool }

def a_lot_is_never_narrower_than_its_pitch():
  {==}

law a_frontage_lot_holds_a_shop_house:
  { U32.is_le(Blk.kind_min_cm(Blk.Ruko{}), Blk.pitch_of(0)) == True{} : Bool }

def a_frontage_lot_holds_a_shop_house():
  {==}

law a_frontage_lot_holds_a_warung:
  { U32.is_le(Blk.kind_min_cm(Blk.Warung{}), Blk.pitch_of(0)) == True{} : Bool }

def a_frontage_lot_holds_a_warung():
  {==}

law a_rear_lot_holds_a_house:
  { U32.is_le(Blk.kind_min_cm(Blk.House{}), Blk.pitch_of(1)) == True{} : Bool }

def a_rear_lot_holds_a_house():
  {==}

law a_rear_lot_holds_a_kos:
  { U32.is_le(Blk.kind_min_cm(Blk.Kos{}), Blk.pitch_of(1)) == True{} : Bool }

def a_rear_lot_holds_a_kos():
  {==}

law a_rear_lot_holds_a_terrace:
  { U32.is_le(Blk.kind_min_cm(Blk.Petak{}), Blk.pitch_of(1)) == True{} : Bool }

def a_rear_lot_holds_a_terrace():
  {==}

law no_building_outgrows_its_ring:
  { Bool.and(U32.is_le(Blk.kind_depth_cm(Blk.Ruko{}), Blk.row_depth_cm()),
    Bool.and(U32.is_le(Blk.kind_depth_cm(Blk.Warung{}), Blk.row_depth_cm()),
    Bool.and(U32.is_le(Blk.kind_depth_cm(Blk.House{}), Blk.row_depth_cm()),
    Bool.and(U32.is_le(Blk.kind_depth_cm(Blk.Kos{}), Blk.row_depth_cm()),
    Bool.and(U32.is_le(Blk.kind_depth_cm(Blk.Petak{}), Blk.row_depth_cm()),
    Bool.and(U32.is_le(Blk.kind_depth_cm(Blk.Filler{}), Blk.row_depth_cm()),
    Bool.and(U32.is_le(Blk.kind_depth_cm(Blk.Minimarket{}), Blk.row_depth_cm()),
    Bool.and(U32.is_le(Blk.kind_depth_cm(Blk.Bengkel{}), Blk.row_depth_cm()),
             U32.is_le(Blk.kind_depth_cm(Blk.Gudang{}), Blk.row_depth_cm()))))))))) == True{} : Bool }

def no_building_outgrows_its_ring():
  {==}

law every_kind_fits_the_lot_it_is_chosen_for:
  { Bool.and(Blk.every_roll_fits(100n, 0, True{}, Blk.pitch_of(0)),
             Blk.every_roll_fits(100n, 0, False{}, Blk.pitch_of(1))) == True{} : Bool }

def every_kind_fits_the_lot_it_is_chosen_for():
  {==}

law every_lot_of_a_block_holds_a_building_that_fits:
  { Bool.and(Blk.lots_fit(2n, 0, 0, 0, 1, 1, Lat.seed_of_town()),
             Blk.lots_fit(2n, 0, 1, 1, 1, 1, Lat.seed_of_town())) == True{} : Bool }

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
  { U32.is_le(U32.mul(2, Pav.widest_crown_cm()), Blk.pitch_of(0)) == True{} : Bool }

def no_two_crowns_meet():
  {==}

law a_prop_stands_on_the_pavement:
  { Bool.and(Pav.prop_on_pavement(1, 1, 0), Bool.and(Pav.prop_on_pavement(1, 1, 1),
             Bool.and(Pav.prop_on_pavement(1, 1, 2), Pav.prop_on_pavement(1, 1, 3)))) == True{} : Bool }

def a_prop_stands_on_the_pavement():
  {==}

law the_props_of_a_frontage_keep_apart:
  { Pav.props_apart(2n, 0, 1, 1, 0, Lat.seed_of_town()) == True{} : Bool }

def the_props_of_a_frontage_keep_apart():
  {==}

law a_pole_spans_forty_metres:
  { U32.is_le(4000, U32.mul(7, Blk.pitch_of(0))) == True{} : Bool }

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
  { Spl.split_holds(Spl.town_cuts(Lat.seed_of_town())) == True{} : Bool }

def the_split_has_every_kind_of_cut_a_fair_share_of_dead_ends_and_no_sliver():
  {==}

# A lot, a prop and a tree stand only where they clear every cut. The test is
# the distance to the segment, and each end of the segment is measured from the
# end: a point beside the cut, past its end, near its end and on a slant.
law a_point_is_clear_of_a_cut_only_by_its_reach:
  { Bool.and(Bool.not(Spl.seg_clear(100, 100, Lat.Pt{0, 0}, Lat.Pt{1000, 0}, 300)),
    Bool.and(Spl.seg_clear(100, 500, Lat.Pt{0, 0}, Lat.Pt{1000, 0}, 300),
    Bool.and(Bool.not(Spl.seg_clear(1200, 0, Lat.Pt{0, 0}, Lat.Pt{1000, 0}, 300)),
    Bool.and(Spl.seg_clear(1400, 0, Lat.Pt{0, 0}, Lat.Pt{1000, 0}, 300),
    Bool.and(Spl.seg_clear(1000, 0, Lat.Pt{0, 0}, Lat.Pt{1000, 1000}, 500),
             Bool.not(Spl.seg_clear(600, 400, Lat.Pt{0, 0}, Lat.Pt{1000, 1000}, 300))))))) == True{} : Bool }

def a_point_is_clear_of_a_cut_only_by_its_reach():
  {==}

# ===========================================================================
# The shift
# ===========================================================================

# A charge is a ticket the moment it starts, with the points Perpol 5/2021
# Pasal 35 puts on the licence for it.
law a_new_charge_is_ticketed_at_once:
  { G.judge([21], Nil{}, 1000) == [G.Ticket{21, 1000, 5}] : List<&2, G.Ticket> }

def a_new_charge_is_ticketed_at_once():
  {==}

# A charge that lasts is one ticket for five seconds, then another.
law a_lasting_charge_is_one_ticket_for_five_seconds:
  { G.judge([21], [G.Ticket{21, 1000, 5}], 1299) == [G.Ticket{21, 1000, 5}] : List<&2, G.Ticket> }

def a_lasting_charge_is_one_ticket_for_five_seconds():
  {==}

law a_lasting_charge_is_ticketed_again_after_five_seconds:
  { G.written(G.judge([21], [G.Ticket{21, 1000, 5}], 1300), 1300) == [G.Ticket{21, 1300, 5}] : List<&2, G.Ticket> }

def a_lasting_charge_is_ticketed_again_after_five_seconds():
  {==}

# A charge that stops and starts again is a new ticket.
law a_charge_that_ends_is_dropped:
  { G.judge([], [G.Ticket{21, 1000, 5}], 1010) == [] : List<&2, G.Ticket> }

def a_charge_that_ends_is_dropped():
  {==}

law a_shift_starts_with_a_clean_licence:
  { G.points_of(G.shift_start(20261024)) == 0 : U32 }

def a_shift_starts_with_a_clean_licence():
  {==}

# Perpol 5/2021 Pasal 38: at 12 points the licence is held, and the shift ends.
law eleven_points_keep_the_shift_going:
  { G.phase_after(False{}, 11, 0) == G.Running{} : G.Phase }

def eleven_points_keep_the_shift_going():
  {==}

law twelve_points_end_the_shift:
  { G.phase_after(False{}, 12, 0) == G.Held{} : G.Phase }

def twelve_points_end_the_shift():
  {==}

law a_crash_ends_the_shift:
  { G.phase_after(True{}, 0, 0) == G.Wrecked{} : G.Phase }

def a_crash_ends_the_shift():
  {==}

# A charge that puts no points on the licence is a warning, given once while
# it lasts.
law a_warning_is_given_once_while_it_lasts:
  { G.judge([52], [G.Ticket{52, 1000, 0}], 1300) == [G.Ticket{52, 1000, 0}] : List<&2, G.Ticket> }

def a_warning_is_given_once_while_it_lasts():
  {==}

# Pasal 108 ayat (1): a shift starts in the kerb lane.
law a_shift_starts_in_the_kerb_lane:
  { G.lane_of(G.player_of(G.drive_of(G.shift_start(20261024)))) == G.Outer{} : G.Lane }

def a_shift_starts_in_the_kerb_lane():
  {==}

law a_shift_lasts_four_minutes:
  { G.shift_ticks() == 14400 : U32 }

def a_shift_lasts_four_minutes():
  {==}

law the_shift_runs_until_the_clock_is_out:
  { G.phase_after(False{}, 0, 14399) == G.Running{} : G.Phase }

def the_shift_runs_until_the_clock_is_out():
  {==}

law the_shift_is_over_when_the_clock_is_out:
  { G.phase_after(False{}, 0, 14400) == G.Over{} : G.Phase }

def the_shift_is_over_when_the_clock_is_out():
  {==}

# A passenger boards, or is set down, only when the car stands still at the
# stop on the main road.
law a_passenger_boards_at_a_standstill:
  { G.at_order(G.Order{False{}, 1, 3, True{}, 0, 41700, 0, 0}, G.Leg{1, 3, 1, 64972}, 42000, 0, False{}) == True{} : Bool }

def a_passenger_boards_at_a_standstill():
  {==}

law a_rolling_car_takes_no_passenger:
  { G.at_order(G.Order{False{}, 1, 3, True{}, 0, 41700, 0, 0}, G.Leg{1, 3, 1, 64972}, 42000, 1, False{}) == False{} : Bool }

def a_rolling_car_takes_no_passenger():
  {==}

law a_car_25_metres_off_the_stop_takes_no_passenger:
  { G.at_order(G.Order{False{}, 1, 3, True{}, 0, 41700, 0, 0}, G.Leg{1, 3, 1, 64972}, 44200, 0, False{}) == False{} : Bool }

def a_car_25_metres_off_the_stop_takes_no_passenger():
  {==}

# Driven the other way, the stop is the same distance from the road's west
# crossing.
law a_stop_is_the_same_place_either_way:
  { G.at_order(G.Order{False{}, 1, 3, True{}, 0, 41700, 0, 0}, G.Leg{2, 3, 3, 64972}, 23272, 0, False{}) == True{} : Bool }

def a_stop_is_the_same_place_either_way():
  {==}

law a_fare_is_5000_and_5_a_metre:
  { G.fare_for(100000) == 10000 : U32 }

def a_fare_is_5000_and_5_a_metre():
  {==}

law a_drop_off_on_time_pays_the_fare:
  { G.paid(9000, 100, 100) == 9000 : U32 }

def a_drop_off_on_time_pays_the_fare():
  {==}

law a_late_drop_off_pays_half:
  { G.paid(9000, 100, 101) == 4500 : U32 }

def a_late_drop_off_pays_half():
  {==}

# ===========================================================================
# Lights
# ===========================================================================

# An approach shows green for eight seconds, amber for three, then red.
law the_light_is_green_for_eight_seconds:
  { Bool.and(U32.is_eq(G.light_of(0), 0), U32.is_eq(G.light_of(479), 0)) == True{} : Bool }

def the_light_is_green_for_eight_seconds():
  {==}

law the_light_is_amber_for_three_seconds:
  { Bool.and(U32.is_eq(G.light_of(480), 1), U32.is_eq(G.light_of(659), 1)) == True{} : Bool }

def the_light_is_amber_for_three_seconds():
  {==}

law the_light_is_red_after_amber:
  { G.light_of(660) == 2 : U32 }

def the_light_is_red_after_amber():
  {==}

law the_two_roads_of_a_crossing_are_never_green_together:
  { G.never_both_green(1440n, 0) == True{} : Bool }

def the_two_roads_of_a_crossing_are_never_green_together():
  {==}

# Crossing (1, 1) is on no arterial, so it has no lights.
law a_crossing_of_collectors_has_no_lights:
  { G.light_at(20261024, 1, 1, 1, 0) == 3 : U32 }

def a_crossing_of_collectors_has_no_lights():
  {==}

# Pasal 106 ayat (4) huruf c: passing a red light is charged under rule 7.
law running_a_red_light_is_charged:
  { R.contains(7, R.charges(G.scenario_at(G.cruising(1000), Nil{}, M.Urban{}, False{}, True{}))) == True{} : Bool }

def running_a_red_light_is_charged():
  {==}

law passing_on_green_is_charged_nothing:
  { G.spread(R.charges(G.scenario_at(G.cruising(1000), Nil{}, M.Urban{}, False{}, False{}))) == Nil{} : List<&2, U32> }

def passing_on_green_is_charged_nothing():
  {==}

# ===========================================================================
# The rating and the ramp
# ===========================================================================

law a_shift_starts_at_five_stars:
  { G.stars_of(G.shift_start(20261024)) == 50 : U32 }

def a_shift_starts_at_five_stars():
  {==}

# Every point a ticket puts on the licence costs a tenth of a star.
law a_five_point_ticket_costs_half_a_star:
  { G.stars_lost(50, 5) == 45 : U32 }

def a_five_point_ticket_costs_half_a_star():
  {==}

law the_rating_never_falls_below_one_star:
  { G.stars_lost(12, 5) == 10 : U32 }

def the_rating_never_falls_below_one_star():
  {==}

law a_drop_off_on_time_earns_two_tenths:
  { G.stars_after(40, True{}, False{}) == 42 : U32 }

def a_drop_off_on_time_earns_two_tenths():
  {==}

law the_rating_never_rises_above_five_stars:
  { G.stars_after(49, True{}, False{}) == 50 : U32 }

def the_rating_never_rises_above_five_stars():
  {==}

law a_late_drop_off_costs_half_a_star:
  { G.stars_after(40, True{}, True{}) == 35 : U32 }

def a_late_drop_off_costs_half_a_star():
  {==}

law a_fare_at_four_stars_pays_four_fifths:
  { G.rated(10000, 40) == 8000 : U32 }

def a_fare_at_four_stars_pays_four_fifths():
  {==}

# Each passenger served, up to five, asks for 0.6 m a second more.
law a_later_order_allows_less_time:
  { Bool.and(U32.is_eq(G.allow_for(60000, 0), 6900), U32.is_eq(G.allow_for(60000, 5), 4900)) == True{} : Bool }

def a_later_order_allows_less_time():
  {==}

# Traffic thickens: at the start a fresh car comes back 70 to 120 m ahead,
# late in the shift 70 to 95 m.
law late_traffic_comes_back_closer:
  { U32.is_lt(G.respawn_gap(3, 15000), 9500) == True{} : Bool }

def late_traffic_comes_back_closer():
  {==}
