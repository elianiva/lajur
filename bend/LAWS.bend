# Claims about the law. Each law names one requirement and states it in full.
# PROOF.bend proves every law here; `bend PROOF.bend` prints ALL PROOFS CHECK
# only when the model and the claims agree.
#
# Grouped by the instrument the requirement comes from. UU 22/2009 first, then
# its implementing regulations, then the two instruments the corpus rests on.
import Base
import ./model.bend as M
import ./rules.bend as R
import ./vehicle.bend as V
import ./network.bend as N
import ./licence.bend as L
import ./safety.bend as S
import ./signs.bend as SG
import ./service.bend as SV
import ./works.bend as W

# ===========================================================================
# UU 22/2009 — a driver in a situation
# ===========================================================================

law keep_to_the_left:
  for s: R.Side
  { R.contains(1, R.charges(R.with_road(R.road_side(s)))) == Bool.not(R.side_is_left(s)) : Bool }

law overtake_on_the_right:
  for s: R.Side
  { R.contains(2, R.charges(R.with_move(R.move_overtake(True{}, s, False{})))) == R.side_is_left(s) : Bool }

law do_not_pass_a_vehicle_signalling_right:
  for b: Bool
  { R.contains(3, R.charges(R.with_move(R.move_overtake(True{}, R.Right{}, b)))) == b : Bool }

law leave_room_for_oncoming_traffic:
  for b: Bool
  { R.contains(4, R.charges(R.with_priority(R.pri_oncoming(True{}, b)))) == Bool.not(b) : Bool }

law downhill_gives_way_to_uphill:
  for b: Bool
  { R.contains(5, R.charges(R.with_priority(R.pri_downhill(b)))) == Bool.not(b) : Bool }

law obey_the_officer_first:
  for b: Bool
  { R.contains(6, R.charges(R.with_road(R.road_officer(True{}, b)))) == Bool.not(b) : Bool }

law stop_at_a_red_light:
  for b: Bool
  { R.contains(7, R.charges(R.with_road(R.road_signal(b)))) == b : Bool }

law obey_a_prohibitive_sign:
  for b: Bool
  { R.contains(8, R.charges(R.with_road(R.road_sign(b)))) == b : Bool }

law obey_a_road_marking:
  for b: Bool
  { R.contains(9, R.charges(R.with_road(R.road_marking(b)))) == b : Bool }

# Pasal 103 and 104 ayat (3): what an officer directs replaces the signal, the
# sign and the marking, but only for a driver who obeys it.
law an_obeyed_officer_outranks_a_red_light:
  for b: Bool
  { R.contains(7, R.charges(R.with_road(R.road_officer_signal(b, True{})))) == Bool.not(b) : Bool }

law an_obeyed_officer_outranks_a_sign:
  for b: Bool
  { R.contains(8, R.charges(R.with_road(R.road_officer_sign(b, True{})))) == Bool.not(b) : Bool }

law an_obeyed_officer_outranks_a_marking:
  for b: Bool
  { R.contains(9, R.charges(R.with_road(R.road_officer_marking(b, True{})))) == Bool.not(b) : Bool }

law signal_before_turning:
  for b: Bool
  { R.contains(10, R.charges(R.with_move(R.move_turn(True{}, b)))) == Bool.not(b) : Bool }

law signal_before_changing_lane:
  for b: Bool
  { R.contains(11, R.charges(R.with_move(R.move_lane_change(True{}, b)))) == Bool.not(b) : Bool }

law bike_driver_must_wear_helmet:
  for b: Bool
  { R.contains(12, R.charges(R.with_bike(0, b, True{}))) == Bool.not(b) : Bool }

law pillion_must_wear_helmet:
  for b: Bool
  { R.contains(13, R.charges(R.with_bike(1, True{}, b))) == Bool.not(b) : Bool }

law one_pillion_without_a_sidecar:
  { R.passenger_counts_ok() == True{} : Bool }

law seatbelt_in_a_cabin:
  for b: Bool
  { R.contains(15, R.charges(R.with_gear(R.gear_seatbelt(b, True{})))) == Bool.not(b) : Bool }

law seatbelt_without_a_cabin:
  for b: Bool
  { R.contains(16, R.charges(R.with_gear(R.gear_seatbelt(b, False{})))) == Bool.not(b) : Bool }

law no_phone_while_driving:
  for b: Bool
  { R.contains(17, R.charges(R.with_gear(R.gear_phone(b)))) == b : Bool }

law give_way_to_a_pedestrian:
  for b: Bool
  { R.contains(18, R.charges(R.with_priority(R.pri_pedestrian(True{}, b)))) == Bool.not(b) : Bool }

law lights_at_night:
  for b: Bool
  { R.contains(19, R.charges(R.with_gear(R.gear_lights(True{}, b)))) == Bool.not(b) : Bool }

law bike_lights_by_day:
  for b: Bool
  { R.contains(20, R.charges(R.with_bike_lights(b))) == Bool.not(b) : Bool }

law fifty_is_allowed_in_a_city:
  { R.contains(21, R.charges(R.with_move(R.move_speed(50)))) == False{} : Bool }

law fifty_one_is_speeding:
  { R.contains(21, R.charges(R.with_move(R.move_speed(51)))) == True{} : Bool }

law carry_a_licence:
  for b: Bool
  { R.contains(22, R.charges(R.with_docs(R.docs_sim(b)))) == Bool.not(b) : Bool }

law carry_a_registration:
  for b: Bool
  { R.contains(23, R.charges(R.with_docs(R.docs_stnk(b)))) == Bool.not(b) : Bool }

law carry_a_test_certificate:
  for b: Bool
  { R.contains(24, R.charges(R.with_docs(R.docs_kir(b)))) == Bool.not(b) : Bool }

law stop_at_a_closed_crossing:
  for b: Bool
  { R.contains(25, R.charges(R.with_road(R.road_railway(b)))) == b : Bool }

law no_racing:
  for b: Bool
  { R.contains(26, R.charges(R.with_move(R.move_racing(b)))) == b : Bool }

law mark_a_breakdown:
  for b: Bool
  { R.contains(27, R.charges(R.with_move(R.move_stop_emergency(True{}, b)))) == Bool.not(b) : Bool }

# Pasal 121 ayat (2): the duty to set out a warning does not reach a motorcycle
# without a sidecar, and does reach one with a sidecar.
law a_bike_needs_no_triangle:
  for s: Bool
  { R.contains(27, R.charges(R.bike_stop_emergency(s, False{}))) == s : Bool }

law stay_after_a_crash:
  for b: Bool
  { R.contains(28, R.charges(R.with_move(R.move_accident(b)))) == b : Bool }

law park_where_it_is_allowed:
  for b: Bool
  { R.contains(29, R.charges(R.with_move(R.move_stopping(True{}, b)))) == Bool.not(b) : Bool }

law signal_before_slowing:
  for b: Bool
  { R.contains(30, R.charges(R.with_move(R.move_slowing(True{}, b)))) == Bool.not(b) : Bool }

law give_way_at_an_unguarded_junction:
  for b: Bool
  { R.contains(31, R.charges(R.with_junction(True{}, False{}, b))) == Bool.not(b) : Bool }

law give_way_on_a_roundabout:
  for b: Bool
  { R.contains(32, R.charges(R.with_junction(False{}, True{}, b))) == Bool.not(b) : Bool }

law fit_a_number_plate:
  for b: Bool
  { R.contains(33, R.charges(R.with_gear(R.gear_plate(b)))) == Bool.not(b) : Bool }

law four_wheels_must_be_roadworthy:
  for b: Bool
  { R.contains(34, R.charges(R.with_gear(R.gear_roadworthy(b)))) == Bool.not(b) : Bool }

law a_motorcycle_meets_the_technical_rules:
  for b: Bool
  { R.contains(35, R.charges(R.with_bike_technical(b))) == Bool.not(b) : Bool }

law a_car_meets_the_technical_rules:
  for b: Bool
  { R.contains(36, R.charges(R.with_gear(R.gear_technical(b)))) == Bool.not(b) : Bool }

law no_accessory_that_endangers:
  for b: Bool
  { R.contains(37, R.charges(R.with_gear(R.gear_interference(b)))) == b : Bool }

law carry_the_four_wheel_kit:
  for b: Bool
  { R.contains(38, R.charges(R.with_gear(R.gear_spare(b)))) == Bool.not(b) : Bool }

law a_modification_forces_a_retest:
  for b: Bool
  { R.contains(39, R.charges(R.with_move(R.move_modified(b)))) == b : Bool }

law a_bicycle_may_not_hold_on:
  for b: Bool
  { R.contains(40, R.charges(R.with_bicycle(b))) == b : Bool }

law goods_follow_the_named_road_class:
  for b: Bool
  { R.contains(41, R.charges(R.with_truck_route(b))) == Bool.not(b) : Bool }

law public_transport_stops_only_where_allowed:
  for b: Bool
  { R.contains(42, R.charges(R.with_bus_stop(b))) == Bool.not(b) : Bool }

law a_goods_vehicle_does_not_carry_people:
  for b: Bool
  { R.contains(43, R.charges(R.with_load(R.load_truck(False{}, b, True{})))) == b : Bool }

law special_goods_meet_their_rules:
  for b: Bool
  { R.contains(44, R.charges(R.with_load(R.load_special_goods(b)))) == Bool.not(b) : Bool }

law goods_carry_a_manifest:
  for b: Bool
  { R.contains(45, R.charges(R.with_truck_manifest(b))) == Bool.not(b) : Bool }

law do_not_overload:
  for b: Bool
  { R.contains(46, R.charges(R.with_load(R.load_truck(b, False{}, True{})))) == b : Bool }

law call_at_the_terminal:
  for b: Bool
  { R.contains(47, R.charges(R.with_bus_terminal(b))) == Bool.not(b) : Bool }

law insure_the_passengers:
  for b: Bool
  { R.contains(48, R.charges(R.with_bus_insurance(b, True{}))) == Bool.not(b) : Bool }

law insure_the_crew:
  for b: Bool
  { R.contains(49, R.charges(R.with_bus_insurance(True{}, b))) == Bool.not(b) : Bool }

law let_the_priority_vehicle_through:
  for b: Bool
  { R.contains(50, R.charges(R.with_emergency(True{}, b))) == Bool.not(b) : Bool }

# The penalties, as the statute states them.
law helmet_costs_one_month_and_250000:
  { Bool.and(U32.is_eq(R.months_of(12), 1), U32.is_eq(R.fine_of(12), 250000)) == True{} : Bool }

law a_phone_costs_three_months_and_750000:
  { Bool.and(U32.is_eq(R.months_of(17), 3), U32.is_eq(R.fine_of(17), 750000)) == True{} : Bool }

law speeding_costs_two_months_and_500000:
  { Bool.and(U32.is_eq(R.months_of(21), 2), U32.is_eq(R.fine_of(21), 500000)) == True{} : Bool }

law no_licence_costs_one_month_and_250000:
  { Bool.and(U32.is_eq(R.months_of(22), 1), U32.is_eq(R.fine_of(22), 250000)) == True{} : Bool }

law no_registration_costs_two_months_and_500000:
  { Bool.and(U32.is_eq(R.months_of(23), 2), U32.is_eq(R.fine_of(23), 500000)) == True{} : Bool }

law racing_costs_a_year_and_3000000:
  { Bool.and(U32.is_eq(R.months_of(26), 12), U32.is_eq(R.fine_of(26), 3000000)) == True{} : Bool }

law a_closed_crossing_costs_three_months_and_750000:
  { Bool.and(U32.is_eq(R.months_of(25), 3), U32.is_eq(R.fine_of(25), 750000)) == True{} : Bool }

law leaving_a_crash_costs_three_years_and_75000000:
  { Bool.and(U32.is_eq(R.months_of(28), 36), U32.is_eq(R.fine_of(28), 75000000)) == True{} : Bool }

law bike_lights_by_day_cost_fifteen_days_and_100000:
  { Bool.and(U32.is_eq(R.days_of(20), 15), U32.is_eq(R.fine_of(20), 100000)) == True{} : Bool }

# ===========================================================================
# The catalogue itself
# ===========================================================================

law the_catalogue_has_fifty_rules:
  { R.rule_count() == 50n : Nat }

law eight_instruments_are_modelled:
  { M.instrument_count() == 8 : U32 }

law every_rule_names_its_article:
  { R.articles_named() == True{} : Bool }

law a_stated_penalty_names_its_sanction:
  { R.sanctions_complete() == True{} : Bool }

law tiers_follow_precedence:
  { R.tiers_ok() == True{} : Bool }

law the_golden_corpus_passes:
  { R.corpus_passes() == True{} : Bool }

law every_verdict_id_is_catalogued:
  { R.corpus_catalogued() == True{} : Bool }

law every_verdict_is_in_order:
  { R.corpus_sorted() == True{} : Bool }

# ===========================================================================
# PM 111/2015 — speed
# ===========================================================================

law a_settlement_is_30:
  { M.speed_limit(M.Residential{}) == 30 : U32 }

law a_city_is_50:
  { M.speed_limit(M.Urban{}) == 50 : U32 }

law an_intercity_road_is_80:
  { M.speed_limit(M.Intercity{}) == 80 : U32 }

law a_motorway_is_100:
  { M.speed_limit(M.Motorway{}) == 100 : U32 }

law a_motorway_is_at_least_60:
  { M.speed_floor(M.Motorway{}) == 60 : U32 }

law only_a_motorway_has_a_floor:
  { Bool.and(U32.is_zero(M.speed_floor(M.Residential{})),
  Bool.and(U32.is_zero(M.speed_floor(M.Urban{})),
           U32.is_zero(M.speed_floor(M.Intercity{})))) == True{} : Bool }

law a_limit_binds_once_it_is_signed:
  { N.limit_needs_a_sign() == True{} : Bool }

law four_grounds_lower_a_limit:
  { M.ground_count() == 4 : U32 }

law accident_history_is_read_over_three_years:
  { M.accident_window_years() == 3 : U32 }

# ===========================================================================
# Perpol 5/2021 — licences
# ===========================================================================

law a_car_licence_covers_3500_kg:
  { M.sim_max_weight(M.A{}) == 3500 : U32 }

law a_bus_licence_has_no_weight_ceiling:
  { M.sim_max_weight(M.BI{}) == 0 : U32 }

law a_motorcycle_licence_covers_250_cc:
  { M.sim_max_cc(M.C{}) == 250 : U32 }

law the_middle_motorcycle_licence_covers_500_cc:
  { M.sim_max_cc(M.CI{}) == 500 : U32 }

law the_large_motorcycle_licence_has_no_ceiling:
  { M.sim_max_cc(M.CII{}) == 0 : U32 }

law a_motorcycle_licence_requires_17:
  { M.min_age(M.C{}) == 17 : U32 }

law a_light_car_licence_requires_17:
  { M.min_age(M.A{}) == 17 : U32 }

law a_big_truck_licence_requires_21:
  { M.min_age(M.BII{}) == 21 : U32 }

law a_public_big_truck_licence_requires_23:
  { M.min_age(M.BIIGeneral{}) == 23 : U32 }

law only_the_international_licence_has_no_age:
  { M.no_age_classes() == True{} : Bool }

law a_licence_lasts_five_years:
  { M.sim_validity_months(M.A{}) == 60 : U32 }

law an_international_licence_lasts_three_years:
  { M.sim_validity_months(M.International{}) == 36 : U32 }

law a_light_car_licence_covers_a_1500_kg_car:
  { M.sim_covers_vehicle(M.A{}, 1500, 0) == True{} : Bool }

law a_light_car_licence_stops_at_3500_kg:
  { M.sim_covers_vehicle(M.A{}, 4000, 0) == False{} : Bool }

law a_motorcycle_licence_covers_a_250_cc_bike:
  { M.sim_covers_vehicle(M.C{}, 200, 250) == True{} : Bool }

law a_motorcycle_licence_stops_at_250_cc:
  { M.sim_covers_vehicle(M.C{}, 200, 400) == False{} : Bool }

law a_big_licence_has_no_weight_ceiling:
  { M.sim_covers_vehicle(M.BI{}, 12000, 0) == True{} : Bool }

law a_personal_licence_is_not_for_public_carrying:
  { Bool.and(Bool.not(M.sim_public(M.A{})), Bool.not(M.sim_public(M.C{}))) == True{} : Bool }

law a_general_licence_is_for_public_carrying:
  { Bool.and(M.sim_public(M.AGeneral{}), M.sim_public(M.BIGeneral{})) == True{} : Bool }

law four_requirements_precede_a_licence:
  { L.requirements_count() == 4 : U32 }

law health_has_two_parts:
  { L.health_check_count() == 2 : U32 }

law physical_health_has_three_checks:
  { L.physical_parts() == 3 : U32 }

law psychological_health_has_three_aspects:
  { L.psychological_parts() == 3 : U32 }

law a_doctor_letter_lasts_fourteen_days:
  { L.doctor_letter_days() == 14 : U32 }

law a_psychology_letter_lasts_six_months:
  { L.psych_letter_months() == 6 : U32 }

law a_test_has_three_stages:
  { L.test_stages() == 3 : U32 }

law the_pass_mark_is_70:
  { L.pass_mark() == 70 : U32 }

law two_retakes_within_fourteen_days:
  { Bool.and(U32.is_eq(L.retakes(), 2), U32.is_eq(L.retake_window_days(), 14)) == True{} : Bool }

law the_theory_paper_has_two_languages:
  { L.theory_languages() == 2 : U32 }

law upgrading_a_class_needs_twelve_months:
  { L.upgrade_holding_months() == 12 : U32 }

law issuing_a_licence_runs_five_steps:
  { L.issue_steps() == 5 : U32 }

law the_international_licence_needs_a_national_one:
  { L.international_needs_national_licence() == True{} : Bool }

# ===========================================================================
# PP 79/2013 — the road network
# ===========================================================================

law a_road_has_one_of_four_functions:
  { N.function_count() == 4 : U32 }

law an_artery_carries_the_longest_trips:
  { Bool.and(N.carries_long_distance(M.Arteri{}), Bool.not(N.carries_long_distance(M.Lokal{}))) == True{} : Bool }

law class_one_takes_a_ten_tonne_axle:
  { M.class_max_axle(M.ClassI{}) == 10 : U32 }

law class_two_takes_an_eight_tonne_axle:
  { M.class_max_axle(M.ClassII{}) == 8 : U32 }

law a_class_three_road_is_narrower:
  { M.class_max_width(M.ClassIII{}) == 2100 : U32 }

law class_one_takes_an_eighteen_metre_vehicle:
  { M.class_max_length(M.ClassI{}) == 18000 : U32 }

law class_two_takes_a_twelve_metre_vehicle:
  { M.class_max_length(M.ClassII{}) == 12000 : U32 }

law a_class_three_road_is_lower:
  { M.class_max_height(M.ClassIII{}) == 3500 : U32 }

law a_class_one_road_takes_more_than_a_class_three:
  { N.class_admits_more() == True{} : Bool }

law a_road_class_is_published_on_a_sign:
  { N.class_is_signed() == True{} : Bool }

# ===========================================================================
# PM 13/2014 — signs
# ===========================================================================

law there_are_four_sign_families:
  { M.sign_count() == 4 : U32 }

law a_warning_sign_is_yellow_with_a_black_border:
  { Bool.and(M.same_colour(M.sign_base(M.Warning{}), M.Yellow{}),
             M.same_colour(M.sign_border(M.Warning{}), M.Black{})) == True{} : Bool }

law a_prohibition_sign_is_white_with_a_red_border:
  { Bool.and(M.same_colour(M.sign_base(M.Prohibition{}), M.White{}),
             M.same_colour(M.sign_border(M.Prohibition{}), M.Red{})) == True{} : Bool }

law a_command_sign_is_blue_with_white_marks:
  { Bool.and(M.same_colour(M.sign_base(M.Command{}), M.Blue{}),
             M.same_colour(M.sign_symbol(M.Command{}), M.White{})) == True{} : Bool }

law a_guidance_sign_is_green_with_white_marks:
  { Bool.and(M.same_colour(M.sign_base(M.Guidance{}), M.Green{}),
             M.same_colour(M.sign_symbol(M.Guidance{}), M.White{})) == True{} : Bool }

law a_temporary_warning_sign_is_orange:
  { M.same_colour(M.sign_base_temporary(M.Warning{}), M.Orange{}) == True{} : Bool }

law an_end_of_prohibition_sign_has_a_black_border:
  { M.same_colour(M.sign_border_end_of_ban(), M.Black{}) == True{} : Bool }

law a_sign_stands_sixty_centimetres_off_the_shoulder:
  { N.shoulder_clearance_cm() == 60 : U32 }

law a_median_sign_stands_thirty_centimetres_off_the_edge:
  { N.median_clearance_cm() == 30 : U32 }

law a_leaf_comes_in_four_sizes:
  { N.leaf_sizes() == 4 : U32 }

law every_leaf_carries_the_transport_logo:
  { N.leaf_needs_logo() == True{} : Bool }

law a_national_route_number_is_a_hexagon:
  { N.route_number_sides(True{}) == 6 : U32 }

law a_tourism_sign_is_brown:
  { M.same_colour(N.tourism_base_is_brown(), M.Brown{}) == True{} : Bool }

# ---------------------------------------------------------------------------
# PM 13/2014 — the catalogue: every sign the seven Lampiran tables list
# ---------------------------------------------------------------------------

law the_catalogue_holds_347_signs:
  { SG.sign_count() == 347 : U32 }

law the_conventional_tables_hold_283_signs:
  { SG.conventional_count() == 283 : U32 }

law the_electronic_table_holds_64_piktograms:
  { SG.count_table(SG.Elektronik{}, SG.signs()) == 64 : U32 }

law each_sign_table_holds_its_stated_number:
  for t: SG.Table
  { SG.count_table(t, SG.signs()) == SG.table_size(t) : U32 }

law the_catalogue_has_72_groups:
  { SG.group_count() == 72 : U32 }

law the_piktogram_rambu_peringatan_group_holds_29_signs:
  { SG.count_group("Piktogram Rambu Peringatan", SG.signs()) == 29 : U32 }

law the_pesan_peringatan_group_holds_0_signs:
  { SG.count_group("Pesan Peringatan", SG.signs()) == 0 : U32 }

law the_piktogram_rambu_peringatan_dan_pesan_peringatan_group_holds_0_signs:
  { SG.count_group("Piktogram Rambu Peringatan dan Pesan Peringatan", SG.signs()) == 0 : U32 }

law the_piktogram_rambu_larangan_group_holds_14_signs:
  { SG.count_group("Piktogram Rambu Larangan", SG.signs()) == 14 : U32 }

law the_pesan_larangan_group_holds_0_signs:
  { SG.count_group("Pesan Larangan", SG.signs()) == 0 : U32 }

law the_piktogram_rambu_larangan_dan_pesan_larangan_group_holds_0_signs:
  { SG.count_group("Piktogram Rambu Larangan dan Pesan Larangan", SG.signs()) == 0 : U32 }

law the_piktogram_rambu_perintah_group_holds_18_signs:
  { SG.count_group("Piktogram Rambu Perintah", SG.signs()) == 18 : U32 }

law the_pesan_perintah_group_holds_0_signs:
  { SG.count_group("Pesan Perintah", SG.signs()) == 0 : U32 }

law the_piktogram_rambu_perintah_dan_pesan_perintah_group_holds_0_signs:
  { SG.count_group("Piktogram Rambu Perintah dan Pesan Perintah", SG.signs()) == 0 : U32 }

law the_piktogram_rambu_petunjuk_group_holds_3_signs:
  { SG.count_group("Piktogram Rambu Petunjuk", SG.signs()) == 3 : U32 }

law the_pesan_petunjuk_group_holds_0_signs:
  { SG.count_group("Pesan Petunjuk", SG.signs()) == 0 : U32 }

law the_rambu_peringatan_perubahan_kondisi_alinyemen_horizontal_group_holds_23_signs:
  { SG.count_group("Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", SG.signs()) == 23 : U32 }

law the_rambu_peringatan_perubahan_kondisi_alinyemen_vertikal_group_holds_4_signs:
  { SG.count_group("Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", SG.signs()) == 4 : U32 }

law the_rambu_peringatan_kondisi_jalan_yang_berbahaya_group_holds_10_signs:
  { SG.count_group("Rambu Peringatan Kondisi Jalan yang Berbahaya", SG.signs()) == 10 : U32 }

law the_rambu_peringatan_pengaturan_persinyalan_group_holds_2_signs:
  { SG.count_group("Rambu Peringatan Pengaturan Persinyalan", SG.signs()) == 2 : U32 }

law the_rambu_peringatan_persimpangan_prioritas_group_holds_19_signs:
  { SG.count_group("Rambu Peringatan Persimpangan Prioritas", SG.signs()) == 19 : U32 }

law the_rambu_peringatan_konstruksi_pemisah_jalur_lalu_lintas_group_holds_4_signs:
  { SG.count_group("Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", SG.signs()) == 4 : U32 }

law the_rambu_peringatan_lalu_lintas_kendaraan_bermotor_group_holds_6_signs:
  { SG.count_group("Rambu Peringatan Lalu Lintas Kendaraan Bermotor", SG.signs()) == 6 : U32 }

law the_rambu_peringatan_selain_lalu_lintas_kendaraan_bermotor_group_holds_7_signs:
  { SG.count_group("Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", SG.signs()) == 7 : U32 }

law the_rambu_peringatan_kawasan_rawan_bencana_group_holds_3_signs:
  { SG.count_group("Rambu Peringatan Kawasan Rawan Bencana", SG.signs()) == 3 : U32 }

law the_rambu_peringatan_lainnya_group_holds_10_signs:
  { SG.count_group("Rambu Peringatan Lainnya", SG.signs()) == 10 : U32 }

law the_rambu_peringatan_dengan_kata_kata_group_holds_0_signs:
  { SG.count_group("Rambu Peringatan dengan Kata-kata", SG.signs()) == 0 : U32 }

law the_rambu_keterangan_tambahan_tentang_jarak_lokasi_kritis_group_holds_3_signs:
  { SG.count_group("Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis", SG.signs()) == 3 : U32 }

law the_rambu_peringatan_pengarah_gerakan_lalu_lintas_group_holds_5_signs:
  { SG.count_group("Rambu Peringatan Pengarah Gerakan Lalu Lintas", SG.signs()) == 5 : U32 }

law the_rambu_larangan_berjalan_terus_group_holds_6_signs:
  { SG.count_group("Rambu Larangan Berjalan Terus", SG.signs()) == 6 : U32 }

law the_rambu_larangan_masuk_bagi_kendaraan_bermotor_dan_tidak_bermotor_group_holds_2_signs:
  { SG.count_group("Rambu Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", SG.signs()) == 2 : U32 }

law the_rambu_larangan_masuk_bagi_kendaraan_bermotor_jenis_tertentu_group_holds_13_signs:
  { SG.count_group("Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", SG.signs()) == 13 : U32 }

law the_rambu_larangan_masuk_bagi_kendaraan_tidak_bermotor_jenis_tertentu_group_holds_9_signs:
  { SG.count_group("Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", SG.signs()) == 9 : U32 }

law the_rambu_larangan_masuk_bagi_kendaraan_dengan_berat_dan_dimensi_tertentu_group_holds_12_signs:
  { SG.count_group("Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", SG.signs()) == 12 : U32 }

law the_rambu_larangan_parkir_dan_berhenti_group_holds_2_signs:
  { SG.count_group("Rambu Larangan Parkir dan Berhenti", SG.signs()) == 2 : U32 }

law the_rambu_larangan_pergerakan_lalu_lintas_tertentu_group_holds_8_signs:
  { SG.count_group("Rambu Larangan Pergerakan Lalu Lintas Tertentu", SG.signs()) == 8 : U32 }

law the_rambu_larangan_membunyikan_isyarat_suara_group_holds_0_signs:
  { SG.count_group("Rambu Larangan Membunyikan Isyarat Suara", SG.signs()) == 0 : U32 }

law the_rambu_larangan_dengan_kata_kata_group_holds_0_signs:
  { SG.count_group("Rambu Larangan dengan Kata-kata", SG.signs()) == 0 : U32 }

law the_rambu_batas_akhir_larangan_group_holds_0_signs:
  { SG.count_group("Rambu Batas Akhir Larangan", SG.signs()) == 0 : U32 }

law the_rambu_perintah_mematuhi_arah_yang_ditunjuk_group_holds_6_signs:
  { SG.count_group("Rambu Perintah Mematuhi Arah yang Ditunjuk", SG.signs()) == 6 : U32 }

law the_rambu_perintah_memilih_salah_satu_arah_yang_ditunjuk_group_holds_2_signs:
  { SG.count_group("Rambu Perintah Memilih Salah Satu Arah yang Ditunjuk", SG.signs()) == 2 : U32 }

law the_rambu_perintah_memasuki_bagian_jalan_tertentu_group_holds_3_signs:
  { SG.count_group("Rambu Perintah Memasuki Bagian Jalan Tertentu", SG.signs()) == 3 : U32 }

law the_rambu_perintah_batas_minimum_kecepatan_group_holds_1_signs:
  { SG.count_group("Rambu Perintah Batas Minimum Kecepatan", SG.signs()) == 1 : U32 }

law the_rambu_perintah_penggunaan_rantai_ban_group_holds_1_signs:
  { SG.count_group("Rambu Perintah Penggunaan Rantai Ban", SG.signs()) == 1 : U32 }

law the_rambu_perintah_menggunakan_jalur_atau_lajur_lalu_lintas_khusus_kendaraan_bermotor_group_holds_3_signs:
  { SG.count_group("Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor", SG.signs()) == 3 : U32 }

law the_rambu_perintah_menggunakan_jalur_atau_lajur_lalu_lintas_khusus_kendaraan_tidak_bermotor_group_holds_7_signs:
  { SG.count_group("Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", SG.signs()) == 7 : U32 }

law the_rambu_batas_akhir_perintah_tertentu_group_holds_2_signs:
  { SG.count_group("Rambu Batas Akhir Perintah Tertentu", SG.signs()) == 2 : U32 }

law the_rambu_perintah_dengan_kata_kata_group_holds_0_signs:
  { SG.count_group("Rambu Perintah dengan Kata-kata", SG.signs()) == 0 : U32 }

law the_rambu_petunjuk_pendahulu_jurusan_group_holds_6_signs:
  { SG.count_group("Rambu Petunjuk Pendahulu Jurusan", SG.signs()) == 6 : U32 }

law the_rambu_petunjuk_jurusan_wilayah_dan_lokasi_tertentu_group_holds_0_signs:
  { SG.count_group("Rambu Petunjuk Jurusan Wilayah dan Lokasi Tertentu", SG.signs()) == 0 : U32 }

law the_rambu_petunjuk_jurusan_khusus_lokasi_dan_kawasan_wisata_group_holds_0_signs:
  { SG.count_group("Rambu Petunjuk Jurusan Khusus Lokasi dan Kawasan Wisata", SG.signs()) == 0 : U32 }

law the_rambu_petunjuk_batas_wilayah_group_holds_2_signs:
  { SG.count_group("Rambu Petunjuk Batas Wilayah", SG.signs()) == 2 : U32 }

law the_rambu_petunjuk_batas_jalan_tol_group_holds_4_signs:
  { SG.count_group("Rambu Petunjuk Batas Jalan Tol", SG.signs()) == 4 : U32 }

law the_rambu_petunjuk_lokasi_simpul_transportasi_group_holds_4_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Simpul Transportasi", SG.signs()) == 4 : U32 }

law the_rambu_petunjuk_lokasi_fasilitas_kebersihan_group_holds_2_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Fasilitas Kebersihan", SG.signs()) == 2 : U32 }

law the_rambu_petunjuk_lokasi_fasilitas_komunikasi_group_holds_2_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Fasilitas Komunikasi", SG.signs()) == 2 : U32 }

law the_rambu_petunjuk_lokasi_fasilitas_pemberhentian_angkutan_umum_group_holds_3_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Fasilitas Pemberhentian Angkutan Umum", SG.signs()) == 3 : U32 }

law the_rambu_petunjuk_lokasi_fasilitas_penyeberangan_pejalan_kaki_group_holds_0_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Fasilitas Penyeberangan Pejalan Kaki", SG.signs()) == 0 : U32 }

law the_rambu_petunjuk_lokasi_fasilitas_parkir_group_holds_2_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Fasilitas Parkir", SG.signs()) == 2 : U32 }

law the_rambu_petunjuk_terowongan_group_holds_2_signs:
  { SG.count_group("Rambu Petunjuk Terowongan", SG.signs()) == 2 : U32 }

law the_rambu_petunjuk_fasilitas_tanggap_bencana_group_holds_6_signs:
  { SG.count_group("Rambu Petunjuk Fasilitas Tanggap Bencana", SG.signs()) == 6 : U32 }

law the_rambu_petunjuk_lokasi_peribadatan_group_holds_4_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Peribadatan", SG.signs()) == 4 : U32 }

law the_rambu_petunjuk_lokasi_pemerintahan_dan_pelayanan_umum_group_holds_8_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", SG.signs()) == 8 : U32 }

law the_rambu_petunjuk_lokasi_perbelanjaan_dan_niaga_group_holds_5_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", SG.signs()) == 5 : U32 }

law the_rambu_petunjuk_lokasi_rekreasi_dan_kebudayaan_group_holds_7_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", SG.signs()) == 7 : U32 }

law the_rambu_petunjuk_lokasi_sarana_olahraga_dan_lapangan_terbuka_group_holds_4_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", SG.signs()) == 4 : U32 }

law the_rambu_petunjuk_lokasi_fasilitas_pendidikan_group_holds_2_signs:
  { SG.count_group("Rambu Petunjuk Lokasi Fasilitas Pendidikan", SG.signs()) == 2 : U32 }

law the_rambu_petunjuk_pengaturan_lalu_lintas_group_holds_9_signs:
  { SG.count_group("Rambu Petunjuk Pengaturan Lalu Lintas", SG.signs()) == 9 : U32 }

law the_papan_nama_jalan_group_holds_0_signs:
  { SG.count_group("Papan Nama Jalan", SG.signs()) == 0 : U32 }

law the_rambu_petunjuk_dengan_kata_kata_group_holds_0_signs:
  { SG.count_group("Rambu Petunjuk dengan Kata-kata", SG.signs()) == 0 : U32 }

law the_bentuk_nomor_rute_group_holds_5_signs:
  { SG.count_group("Bentuk Nomor Rute", SG.signs()) == 5 : U32 }

law the_rambu_peringatan_sementara_perubahan_kondisi_alinyemen_horizontal_group_holds_13_signs:
  { SG.count_group("Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", SG.signs()) == 13 : U32 }

law the_rambu_peringatan_sementara_kondisi_jalan_yang_berbahaya_group_holds_3_signs:
  { SG.count_group("Rambu Peringatan Sementara Kondisi Jalan yang Berbahaya", SG.signs()) == 3 : U32 }

law the_rambu_peringatan_sementara_rintangan_di_jalan_group_holds_8_signs:
  { SG.count_group("Rambu Peringatan Sementara Rintangan di Jalan", SG.signs()) == 8 : U32 }

law the_rambu_peringatan_sementara_lainnya_group_holds_6_signs:
  { SG.count_group("Rambu Peringatan Sementara Lainnya", SG.signs()) == 6 : U32 }

law the_rambu_peringatan_sementara_dengan_kata_kata_group_holds_0_signs:
  { SG.count_group("Rambu Peringatan Sementara dengan Kata-kata", SG.signs()) == 0 : U32 }

law the_rambu_keterangan_tambahan_tentang_jarak_lokasi_kritis_sementara_group_holds_3_signs:
  { SG.count_group("Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis Sementara", SG.signs()) == 3 : U32 }

law every_sign_has_a_meaning:
  { SG.all_meaningful(SG.signs()) == True{} : Bool }

law every_sign_sits_in_its_family:
  { SG.all_family_ok(SG.signs()) == True{} : Bool }

law the_catalogue_is_numbered_without_a_gap:
  { SG.numbered(SG.signs(), 1) == True{} : Bool }

law the_papan_tambahan_has_five_kinds:
  { SG.supplement_count() == 5 : U32 }

law the_papan_tambahan_is_numbered:
  { SG.supplements_numbered(SG.supplements(), 1) == True{} : Bool }

law the_catalogue_holds_158_warning_signs:
  { SG.warning_count() == 158 : U32 }

law the_catalogue_holds_66_prohibition_signs:
  { SG.prohibition_count() == 66 : U32 }

law the_catalogue_holds_43_command_signs:
  { SG.command_count() == 43 : U32 }

law the_catalogue_holds_80_guidance_signs:
  { SG.guidance_count() == 80 : U32 }

law the_four_families_cover_every_sign:
  { U32.add(SG.warning_count(), U32.add(SG.prohibition_count(), U32.add(SG.command_count(), SG.guidance_count()))) == SG.sign_count() : U32 }

law a_prohibition_sign_binds_the_driver:
  { SG.binds_driver(M.Prohibition{}) == True{} : Bool }

law a_command_sign_binds_the_driver:
  { SG.binds_driver(M.Command{}) == True{} : Bool }

law a_warning_sign_states_no_duty:
  { SG.binds_driver(M.Warning{}) == False{} : Bool }

law a_guidance_sign_states_no_duty:
  { SG.binds_driver(M.Guidance{}) == False{} : Bool }

# ---------------------------------------------------------------------------
# PM 13/2014 — the operative rule each sign posts, and the charge it produces
# ---------------------------------------------------------------------------

law the_catalogue_posts_109_duties:
  { SG.duty_count() == 109 : U32 }

law every_binding_sign_posts_a_duty:
  { SG.every_binding_sign_posts_a_duty(SG.signs()) == True{} : Bool }

law a_no_stopping_sign_posts_no_stopping:
  { SG.is_no_stopping(SG.posted("III-3a")) == True{} : Bool }

law a_no_parking_sign_posts_no_parking:
  { SG.is_no_parking(SG.posted("III-3b")) == True{} : Bool }

law a_no_left_turn_sign_posts_no_left_turn:
  { SG.is_no_left_turn(SG.posted("III-4b")) == True{} : Bool }

law a_stop_sign_posts_a_stop:
  { SG.is_stop(SG.posted("III-1a")) == True{} : Bool }

law a_give_way_sign_posts_give_way:
  { SG.is_give_way(SG.posted("III-1b")) == True{} : Bool }

law a_keep_left_sign_posts_keep_left:
  { SG.is_keep_left(SG.posted("IV-1a")) == True{} : Bool }

law a_no_entry_sign_posts_no_entry:
  { SG.is_no_entry(SG.posted("III-2a1")) == True{} : Bool }

law a_max_speed_sign_posts_50:
  { SG.max_speed_limit(SG.posted("III-4h")) == 50 : U32 }

law a_min_speed_sign_posts_50:
  { SG.min_speed_limit(SG.posted("IV-4")) == 50 : U32 }

law a_no_right_turn_sign_posts_no_right_turn:
  { SG.same_duty_kind(SG.posted("III-4c"), M.NoRightTurn{}) == True{} : Bool }

law a_no_u_turn_sign_posts_no_u_turn:
  { SG.same_duty_kind(SG.posted("III-4e"), M.NoUTurn{}) == True{} : Bool }

law a_no_overtaking_sign_posts_no_overtaking:
  { SG.same_duty_kind(SG.posted("III-4d"), M.NoOvertaking{}) == True{} : Bool }

law a_keep_right_sign_posts_keep_right:
  { SG.same_duty_kind(SG.posted("IV-1b"), M.KeepRight{}) == True{} : Bool }

law a_turn_left_sign_posts_turn_left:
  { SG.same_duty_kind(SG.posted("IV-1c"), M.TurnLeft{}) == True{} : Bool }

law a_roundabout_sign_posts_roundabout:
  { SG.same_duty_kind(SG.posted("IV-1f"), M.Roundabout{}) == True{} : Bool }

law a_chain_sign_posts_use_chains:
  { SG.same_duty_kind(SG.posted("IV-5"), M.UseChains{}) == True{} : Bool }

law a_bus_lane_sign_posts_a_bus_lane:
  { SG.same_duty_kind(SG.posted("IV-6a2"), M.UseLane{M.Bus{}}) == True{} : Bool }

law a_warning_sign_posts_no_rule:
  { SG.is_no_duty(SG.posted("II-1a")) == True{} : Bool }

law a_guidance_sign_posts_no_rule:
  { SG.is_no_duty(SG.posted("V-1a")) == True{} : Bool }

law stopping_at_a_no_stopping_sign_is_charged:
  { R.contains(8, R.charges(R.sign_stopping(M.NoStopping{}, True{}))) == True{} : Bool }

law driving_past_a_no_stopping_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_stopping(M.NoStopping{}, False{}))) == False{} : Bool }

law stopping_without_a_no_stopping_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_stopping(M.NoDuty{}, True{}))) == False{} : Bool }

law an_emergency_stop_at_a_no_stopping_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_stopping_emergency(M.NoStopping{}, True{}))) == False{} : Bool }

law a_no_stopping_sign_costs_two_months_and_500000:
  { Bool.and(R.contains(8, R.charges(R.sign_stopping(M.NoStopping{}, True{}))),
             Bool.and(U32.is_eq(R.months_of(8), 2), U32.is_eq(R.fine_of(8), 500000))) == True{} : Bool }

law parking_at_a_no_parking_sign_is_charged:
  { R.contains(8, R.charges(R.sign_parking(M.NoParking{}, True{}))) == True{} : Bool }

law a_brief_stop_at_a_no_parking_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_parking(M.NoParking{}, False{}))) == False{} : Bool }

law turning_left_at_a_no_left_turn_sign_is_charged:
  { R.contains(8, R.charges(R.sign_turn(M.NoLeftTurn{}, R.TurnLeft{}))) == True{} : Bool }

law turning_right_at_a_no_left_turn_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_turn(M.NoLeftTurn{}, R.TurnRight{}))) == False{} : Bool }

law turning_back_at_a_no_u_turn_sign_is_charged:
  { R.contains(8, R.charges(R.sign_turn(M.NoUTurn{}, R.TurnBack{}))) == True{} : Bool }

law overtaking_at_a_no_overtaking_sign_is_charged:
  { R.contains(8, R.charges(R.sign_overtaking(M.NoOvertaking{}, True{}))) == True{} : Bool }

law not_overtaking_at_a_no_overtaking_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_overtaking(M.NoOvertaking{}, False{}))) == False{} : Bool }

law exceeding_a_40_sign_at_50_is_charged:
  { R.contains(8, R.charges(R.sign_speed(M.MaxSpeed{40}, 50))) == True{} : Bool }

law driving_at_30_past_a_40_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_speed(M.MaxSpeed{40}, 30))) == False{} : Bool }

law driving_below_a_50_minimum_is_charged:
  { R.contains(8, R.charges(R.sign_speed(M.MinSpeed{50}, 40))) == True{} : Bool }

law driving_at_a_50_minimum_is_not_charged:
  { R.contains(8, R.charges(R.sign_speed(M.MinSpeed{50}, 50))) == False{} : Bool }

law keeping_right_at_a_keep_left_sign_is_charged:
  { R.contains(8, R.charges(R.sign_side(M.KeepLeft{}, R.Right{}))) == True{} : Bool }

law keeping_left_at_a_keep_left_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_side(M.KeepLeft{}, R.Left{}))) == False{} : Bool }

law entering_a_no_car_sign_in_a_car_is_charged:
  { R.contains(8, R.charges(R.sign_vehicle(M.NoEntry{[M.Car{}]}, R.Car{}))) == True{} : Bool }

law a_truck_may_pass_a_no_car_sign:
  { R.contains(8, R.charges(R.sign_vehicle(M.NoEntry{[M.Car{}]}, R.Truck{}))) == False{} : Bool }

law a_motorcycle_is_charged_at_a_no_motorcycle_sign:
  { R.contains(8, R.charges(R.sign_vehicle(M.NoEntry{[M.Motorcycle{}]}, R.Motorcycle{}))) == True{} : Bool }

law a_motorcycle_may_pass_a_non_motorized_ban:
  { R.contains(8, R.charges(R.sign_vehicle(M.NoEntry{[M.NonMotorized{}]}, R.Motorcycle{}))) == False{} : Bool }

law a_bicycle_is_charged_at_a_non_motorized_ban:
  { R.contains(8, R.charges(R.sign_vehicle(M.NoEntry{[M.NonMotorized{}]}, R.Bicycle{}))) == True{} : Bool }

law a_car_is_charged_at_a_no_entry_sign:
  { R.contains(8, R.charges(R.sign_vehicle(M.NoEntry{[M.Any{}]}, R.Car{}))) == True{} : Bool }

law passing_a_stop_sign_without_stopping_is_charged:
  { R.contains(8, R.charges(R.sign_stopping(M.Stop{}, False{}))) == True{} : Bool }

law stopping_at_a_stop_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_stopping(M.Stop{}, True{}))) == False{} : Bool }

law failing_to_yield_at_a_give_way_sign_is_charged:
  { R.contains(8, R.charges(R.sign_priority(M.GiveWay{}, False{}))) == True{} : Bool }

law yielding_at_a_give_way_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_priority(M.GiveWay{}, True{}))) == False{} : Bool }

law driving_without_chains_at_a_chain_sign_is_charged:
  { R.contains(8, R.charges(R.sign_chains(M.UseChains{}, False{}))) == True{} : Bool }

law a_45_tonne_vehicle_at_a_5_tonne_sign_is_charged:
  { R.contains(8, R.charges(R.sign_weight(M.WeightLimit{5}, 45000))) == True{} : Bool }

law a_4_tonne_vehicle_at_a_5_tonne_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_weight(M.WeightLimit{5}, 4000))) == False{} : Bool }

law a_bus_out_of_its_lane_at_a_bus_lane_sign_is_charged:
  { R.contains(8, R.charges(R.sign_lane_vehicle(M.UseLane{M.Bus{}}, R.Bus{}, False{}))) == True{} : Bool }

law a_bus_in_its_lane_at_a_bus_lane_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_lane_vehicle(M.UseLane{M.Bus{}}, R.Bus{}, True{}))) == False{} : Bool }

law following_20_metres_at_a_50_metre_sign_is_charged:
  { R.contains(8, R.charges(R.sign_following(M.NoCloseFollowing{50}, 20))) == True{} : Bool }

law following_60_metres_at_a_50_metre_sign_is_not_charged:
  { R.contains(8, R.charges(R.sign_following(M.NoCloseFollowing{50}, 60))) == False{} : Bool }

law a_4_3_metre_vehicle_at_a_4_2_metre_sign_is_charged:
  { R.contains(8, R.charges(R.sign_size(M.DimensionLimit{2500, 18000, 4200, 10}, 1800, 4500, 4300, 1500))) == True{} : Bool }

law a_10_metre_vehicle_at_a_9_metre_sign_is_charged:
  { R.contains(8, R.charges(R.sign_size(M.LengthLimit{9}, 1800, 10000, 1500, 1500))) == True{} : Bool }

# ---------------------------------------------------------------------------
# PM 13/2014 — where a sign hangs, and what it must carry
# ---------------------------------------------------------------------------

law a_sign_hangs_between_175_and_265_centimetres:
  { Bool.and(U32.is_eq(N.sign_min_height_cm(), 175), U32.is_eq(N.sign_max_height_cm(), 265)) == True{} : Bool }

law an_overhead_sign_hangs_at_least_500_centimetres:
  { N.overhead_min_height_cm() == 500 : U32 }

law a_chevron_hangs_at_120_centimetres:
  { N.chevron_height_cm() == 120 : U32 }

law a_warning_sign_stands_before_the_hazard:
  { N.warning_stands_before_the_hazard() == True{} : Bool }

law a_warning_sign_stands_180_metres_before_a_hazard_over_100:
  { N.warning_distance_m(120) == 180 : U32 }

law a_warning_sign_stands_100_metres_at_100:
  { N.warning_distance_m(100) == 100 : U32 }

law a_warning_sign_stands_100_metres_before_a_hazard_over_80:
  { N.warning_distance_m(90) == 100 : U32 }

law a_warning_sign_stands_80_metres_at_80:
  { N.warning_distance_m(80) == 80 : U32 }

law a_warning_sign_stands_80_metres_before_a_hazard_over_60:
  { N.warning_distance_m(70) == 80 : U32 }

law a_warning_sign_stands_50_metres_before_a_hazard_at_60:
  { N.warning_distance_m(60) == 50 : U32 }

law a_parking_ban_runs_30_metres:
  { N.parking_ban_extent_m() == 30 : U32 }

law a_prohibition_starts_where_the_ban_starts:
  { N.prohibition_starts_at_the_ban() == True{} : Bool }

law a_command_stands_at_the_start_or_end_of_the_order:
  { N.command_stands_at_the_order() == True{} : Bool }

law a_supplement_sits_5_to_10_centimetres_below_the_leaf:
  { Bool.and(U32.is_eq(N.supplement_gap_min_cm(), 5), U32.is_eq(N.supplement_gap_max_cm(), 10)) == True{} : Bool }

law a_supplement_is_twice_as_wide_as_it_is_tall:
  { U32.mul(N.supplement_ratio_tall(), 2) == N.supplement_ratio_wide() : U32 }

law a_supplement_is_white_with_a_black_border:
  { Bool.and(M.same_colour(N.supplement_base(), M.White{}), M.same_colour(N.supplement_border(), M.Black{})) == True{} : Bool }

law a_supplement_is_not_allowed_on_five_kinds_of_sign:
  { N.supplement_forbidden_count() == 5 : U32 }

law a_pole_carries_at_most_two_leaves:
  { N.max_leaves_per_pole() == 2 : U32 }

law a_sign_is_maintained_every_six_months:
  { N.maintenance_months() == 6 : U32 }

law a_sign_is_removed_after_five_years:
  { N.technical_life_years() == 5 : U32 }

law a_sign_may_not_be_obstructed:
  { N.sign_may_not_be_obstructed() == True{} : Bool }

law a_small_leaf_is_for_30:
  { N.same_leaf_size(N.leaf_size_for(30), N.LeafSmall{}) == True{} : Bool }

law a_medium_leaf_is_for_60:
  { N.same_leaf_size(N.leaf_size_for(60), N.LeafMedium{}) == True{} : Bool }

law a_large_leaf_is_for_80:
  { N.same_leaf_size(N.leaf_size_for(80), N.LeafLarge{}) == True{} : Bool }

law a_very_large_leaf_is_for_more_than_80:
  { N.same_leaf_size(N.leaf_size_for(100), N.LeafVeryLarge{}) == True{} : Bool }

# ===========================================================================
# UU 22/2009 — the vehicle
# ===========================================================================

law a_private_car_needs_no_periodic_test:
  { V.needs_periodic_test(V.PassengerCar{}) == False{} : Bool }

law a_motorcycle_needs_no_periodic_test:
  { V.needs_periodic_test(V.Motorcycle{}) == False{} : Bool }

law a_bus_needs_a_periodic_test:
  { V.needs_periodic_test(V.Bus{}) == True{} : Bool }

law a_goods_vehicle_needs_a_periodic_test:
  { V.needs_periodic_test(V.GoodsVehicle{}) == True{} : Bool }

law a_public_car_needs_a_periodic_test:
  { V.needs_periodic_test_when_public(V.PassengerCar{}, True{}) == True{} : Bool }

law a_type_test_comes_before_registration:
  { V.type_test_before_registration() == True{} : Bool }

law a_four_wheel_kit_has_five_parts:
  { V.kit_count() == 5 : U32 }

law a_motorcycle_kit_is_a_helmet:
  { V.motorcycle_kit_is_helmet() == True{} : Bool }

law a_motorcycle_has_nine_technical_items:
  { V.bike_item_count() == 9 : U32 }

law a_four_wheel_vehicle_has_seventeen_technical_items:
  { V.car_item_count() == 17 : U32 }

law no_accessory_may_endanger_traffic:
  { Bool.and(Bool.not(V.accessory_allowed(True{})), V.accessory_allowed(False{})) == True{} : Bool }

law registration_issues_two_documents:
  { V.registration_documents() == 2 : U32 }

law a_plate_carries_three_fields:
  { V.plate_fields() == 3 : U32 }

# ===========================================================================
# PP 37/2017 — safety management
# ===========================================================================

law there_are_five_pillars:
  { S.pillar_count() == 5 : U32 }

law a_national_safety_plan_runs_twenty_years:
  { S.plan_years() == 20 : U32 }

law a_national_safety_plan_is_reviewed_every_five_years:
  { S.plan_review_years() == 5 : U32 }

law a_regional_action_plan_runs_five_years:
  { S.action_plan_years() == 5 : U32 }

law a_regional_action_plan_is_reviewed_every_year:
  { S.action_plan_review_years() == 1 : U32 }

law implementation_is_reviewed_every_three_months:
  { S.implementation_review_months() == 3 : U32 }

law a_safety_system_has_ten_elements:
  { S.element_count() == 10 : U32 }

law a_safety_system_is_due_three_months_after_the_permit:
  { S.system_deadline_months() == 3 : U32 }

law safety_review_runs_every_three_months:
  { S.review_interval_months() == 3 : U32 }

law two_ratios_measure_safety:
  { S.performance_ratios() == 2 : U32 }

law five_kinds_of_action_carry_the_plan:
  { S.action_count() == 5 : U32 }

# ===========================================================================
# PP 30/2021 and UU 22/2009 — service and land use
# ===========================================================================

law three_kinds_of_development_need_an_analysis:
  { SV.development_count() == 3 : U32 }

law a_national_road_puts_approval_with_the_minister:
  { SV.same_authority(SV.approval_authority(True{}, False{}), SV.Minister{}) == True{} : Bool }

law a_provincial_road_puts_approval_with_the_governor:
  { SV.same_authority(SV.approval_authority(False{}, True{}), SV.Governor{}) == True{} : Bool }

law a_local_road_puts_approval_with_the_regent:
  { SV.same_authority(SV.approval_authority(False{}, False{}), SV.Regent{}) == True{} : Bool }

law the_developer_pays_for_the_analysis:
  { SV.analysis_is_developer_duty() == True{} : Bool }

law a_high_impact_development_needs_a_full_document:
  { Bool.and(SV.needs_full_document(True{}), Bool.not(SV.needs_full_document(False{}))) == True{} : Bool }

law a_warning_is_issued_three_times_for_thirty_days:
  { Bool.and(U32.is_eq(SV.warnings(), 3), U32.is_eq(SV.warning_days(), 30)) == True{} : Bool }

law a_terminal_is_trialled_one_month_before_opening:
  { SV.terminal_trial_months() == 1 : U32 }

law a_route_calls_at_its_terminal:
  { Bool.and(SV.terminal_on_route(False{}), Bool.not(SV.terminal_on_route(True{}))) == True{} : Bool }

law a_passenger_carries_three_papers:
  { SV.passenger_paper_count() == 3 : U32 }

law a_goods_shipment_carries_two_papers:
  { SV.goods_paper_count() == 2 : U32 }

law insurance_covers_four_things:
  { SV.insurance_cover_count() == 4 : U32 }

# ===========================================================================
# UU 28/2014 — copyright, and why this corpus may be stored
# ===========================================================================

law a_statute_carries_no_copyright:
  { W.statute_is_exempt() == True{} : Bool }

law five_kinds_of_work_are_exempt:
  { W.exempt_count() == 5 : U32 }

law copyright_lasts_seventy_years_after_the_author:
  { W.term_after_author_dies() == 70 : U32 }

law a_legal_entity_gets_fifty_years:
  { W.term_for_legal_entity() == 50 : U32 }

law applied_art_gets_twenty_five_years:
  { W.term_for_applied_art() == 25 : U32 }

law an_unknown_author_gets_fifty_years:
  { W.term_for_unknown_author() == 50 : U32 }

law traditional_culture_has_no_term:
  { W.term_for_traditional_culture() == 0 : U32 }

law the_longest_term_is_seventy_years:
  { W.longest_term() == 70 : U32 }
