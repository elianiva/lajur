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
