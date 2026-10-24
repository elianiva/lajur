# Proofs for LAWS.bend. One def per law, named `Laws.<law>`.
#
# Almost every law reduces to reflexivity: both sides compute to the same term.
# A law that varies one flag splits on that flag; the two side laws split on
# left and right.
import Base
import ./model.bend as M
import ./rules.bend as R
import ./vehicle.bend as V
import ./network.bend as N
import ./licence.bend as L
import ./safety.bend as S
import ./service.bend as SV
import ./works.bend as W
import ./LAWS.bend as Laws

def Laws.keep_to_the_left(s):
  match s:
    case R.Left{}:
      {==}
    case R.Right{}:
      {==}

def Laws.overtake_on_the_right(s):
  match s:
    case R.Left{}:
      {==}
    case R.Right{}:
      {==}

def Laws.do_not_pass_a_vehicle_signalling_right(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.leave_room_for_oncoming_traffic(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.downhill_gives_way_to_uphill(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.obey_the_officer_first(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.stop_at_a_red_light(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.obey_a_prohibitive_sign(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.obey_a_road_marking(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.signal_before_turning(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.signal_before_changing_lane(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.bike_driver_must_wear_helmet(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.pillion_must_wear_helmet(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.one_pillion_without_a_sidecar():
  {==}

def Laws.seatbelt_in_a_cabin(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.seatbelt_without_a_cabin(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.no_phone_while_driving(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.give_way_to_a_pedestrian(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.lights_at_night(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.bike_lights_by_day(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.fifty_is_allowed_in_a_city():
  {==}

def Laws.fifty_one_is_speeding():
  {==}

def Laws.carry_a_licence(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.carry_a_registration(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.carry_a_test_certificate(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.stop_at_a_closed_crossing(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.no_racing(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.mark_a_breakdown(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.stay_after_a_crash(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.park_where_it_is_allowed(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.signal_before_slowing(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.give_way_at_an_unguarded_junction(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.give_way_on_a_roundabout(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.fit_a_number_plate(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.four_wheels_must_be_roadworthy(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.a_motorcycle_meets_the_technical_rules(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.a_car_meets_the_technical_rules(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.no_accessory_that_endangers(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.carry_the_four_wheel_kit(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.a_modification_forces_a_retest(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.a_bicycle_may_not_hold_on(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.goods_follow_the_named_road_class(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.public_transport_stops_only_where_allowed(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.a_goods_vehicle_does_not_carry_people(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.special_goods_meet_their_rules(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.goods_carry_a_manifest(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.do_not_overload(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.call_at_the_terminal(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.insure_the_passengers(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.insure_the_crew(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.let_the_priority_vehicle_through(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.helmet_costs_one_month_and_250000():
  {==}

def Laws.a_phone_costs_three_months_and_750000():
  {==}

def Laws.speeding_costs_two_months_and_500000():
  {==}

def Laws.no_licence_costs_one_month_and_250000():
  {==}

def Laws.no_registration_costs_two_months_and_500000():
  {==}

def Laws.racing_costs_a_year_and_3000000():
  {==}

def Laws.a_closed_crossing_costs_three_months_and_750000():
  {==}

def Laws.leaving_a_crash_costs_three_years_and_75000000():
  {==}

def Laws.bike_lights_by_day_cost_fifteen_days_and_100000():
  {==}

def Laws.the_catalogue_has_fifty_rules():
  {==}

def Laws.eight_instruments_are_modelled():
  {==}

def Laws.every_rule_names_its_article():
  {==}

def Laws.a_stated_penalty_names_its_sanction():
  {==}

def Laws.tiers_follow_precedence():
  {==}

def Laws.the_golden_corpus_passes():
  {==}

def Laws.every_verdict_id_is_catalogued():
  {==}

def Laws.every_verdict_is_in_order():
  {==}

def Laws.a_settlement_is_30():
  {==}

def Laws.a_city_is_50():
  {==}

def Laws.an_intercity_road_is_80():
  {==}

def Laws.a_motorway_is_100():
  {==}

def Laws.a_motorway_is_at_least_60():
  {==}

def Laws.only_a_motorway_has_a_floor():
  {==}

def Laws.a_limit_binds_once_it_is_signed():
  {==}

def Laws.four_grounds_lower_a_limit():
  {==}

def Laws.accident_history_is_read_over_three_years():
  {==}

def Laws.a_car_licence_covers_3500_kg():
  {==}

def Laws.a_bus_licence_has_no_weight_ceiling():
  {==}

def Laws.a_motorcycle_licence_covers_250_cc():
  {==}

def Laws.the_middle_motorcycle_licence_covers_500_cc():
  {==}

def Laws.the_large_motorcycle_licence_has_no_ceiling():
  {==}

def Laws.a_motorcycle_licence_requires_17():
  {==}

def Laws.a_light_car_licence_requires_17():
  {==}

def Laws.a_big_truck_licence_requires_21():
  {==}

def Laws.a_public_big_truck_licence_requires_23():
  {==}

def Laws.only_the_international_licence_has_no_age():
  {==}

def Laws.a_licence_lasts_five_years():
  {==}

def Laws.an_international_licence_lasts_three_years():
  {==}

def Laws.a_light_car_licence_covers_a_1500_kg_car():
  {==}

def Laws.a_light_car_licence_stops_at_3500_kg():
  {==}

def Laws.a_motorcycle_licence_covers_a_250_cc_bike():
  {==}

def Laws.a_motorcycle_licence_stops_at_250_cc():
  {==}

def Laws.a_big_licence_has_no_weight_ceiling():
  {==}

def Laws.a_personal_licence_is_not_for_public_carrying():
  {==}

def Laws.a_general_licence_is_for_public_carrying():
  {==}

def Laws.four_requirements_precede_a_licence():
  {==}

def Laws.health_has_two_parts():
  {==}

def Laws.physical_health_has_three_checks():
  {==}

def Laws.psychological_health_has_three_aspects():
  {==}

def Laws.a_doctor_letter_lasts_fourteen_days():
  {==}

def Laws.a_psychology_letter_lasts_six_months():
  {==}

def Laws.a_test_has_three_stages():
  {==}

def Laws.the_pass_mark_is_70():
  {==}

def Laws.two_retakes_within_fourteen_days():
  {==}

def Laws.the_theory_paper_has_two_languages():
  {==}

def Laws.upgrading_a_class_needs_twelve_months():
  {==}

def Laws.issuing_a_licence_runs_five_steps():
  {==}

def Laws.the_international_licence_needs_a_national_one():
  {==}

def Laws.a_road_has_one_of_four_functions():
  {==}

def Laws.an_artery_carries_the_longest_trips():
  {==}

def Laws.class_one_takes_a_ten_tonne_axle():
  {==}

def Laws.class_two_takes_an_eight_tonne_axle():
  {==}

def Laws.a_class_three_road_is_narrower():
  {==}

def Laws.class_one_takes_an_eighteen_metre_vehicle():
  {==}

def Laws.class_two_takes_a_twelve_metre_vehicle():
  {==}

def Laws.a_class_three_road_is_lower():
  {==}

def Laws.a_class_one_road_takes_more_than_a_class_three():
  {==}

def Laws.a_road_class_is_published_on_a_sign():
  {==}

def Laws.there_are_four_sign_families():
  {==}

def Laws.a_warning_sign_is_yellow_with_a_black_border():
  {==}

def Laws.a_prohibition_sign_is_white_with_a_red_border():
  {==}

def Laws.a_command_sign_is_blue_with_white_marks():
  {==}

def Laws.a_guidance_sign_is_green_with_white_marks():
  {==}

def Laws.a_temporary_warning_sign_is_orange():
  {==}

def Laws.an_end_of_prohibition_sign_has_a_black_border():
  {==}

def Laws.a_sign_stands_sixty_centimetres_off_the_shoulder():
  {==}

def Laws.a_median_sign_stands_thirty_centimetres_off_the_edge():
  {==}

def Laws.a_leaf_comes_in_four_sizes():
  {==}

def Laws.every_leaf_carries_the_transport_logo():
  {==}

def Laws.a_national_route_number_is_a_hexagon():
  {==}

def Laws.a_tourism_sign_is_brown():
  {==}

def Laws.a_private_car_needs_no_periodic_test():
  {==}

def Laws.a_motorcycle_needs_no_periodic_test():
  {==}

def Laws.a_bus_needs_a_periodic_test():
  {==}

def Laws.a_goods_vehicle_needs_a_periodic_test():
  {==}

def Laws.a_public_car_needs_a_periodic_test():
  {==}

def Laws.a_type_test_comes_before_registration():
  {==}

def Laws.a_four_wheel_kit_has_five_parts():
  {==}

def Laws.a_motorcycle_kit_is_a_helmet():
  {==}

def Laws.a_motorcycle_has_nine_technical_items():
  {==}

def Laws.a_four_wheel_vehicle_has_seventeen_technical_items():
  {==}

def Laws.no_accessory_may_endanger_traffic():
  {==}

def Laws.registration_issues_two_documents():
  {==}

def Laws.a_plate_carries_three_fields():
  {==}

def Laws.there_are_five_pillars():
  {==}

def Laws.a_national_safety_plan_runs_twenty_years():
  {==}

def Laws.a_national_safety_plan_is_reviewed_every_five_years():
  {==}

def Laws.a_regional_action_plan_runs_five_years():
  {==}

def Laws.a_regional_action_plan_is_reviewed_every_year():
  {==}

def Laws.implementation_is_reviewed_every_three_months():
  {==}

def Laws.a_safety_system_has_ten_elements():
  {==}

def Laws.a_safety_system_is_due_three_months_after_the_permit():
  {==}

def Laws.safety_review_runs_every_three_months():
  {==}

def Laws.two_ratios_measure_safety():
  {==}

def Laws.five_kinds_of_action_carry_the_plan():
  {==}

def Laws.three_kinds_of_development_need_an_analysis():
  {==}

def Laws.a_national_road_puts_approval_with_the_minister():
  {==}

def Laws.a_provincial_road_puts_approval_with_the_governor():
  {==}

def Laws.a_local_road_puts_approval_with_the_regent():
  {==}

def Laws.the_developer_pays_for_the_analysis():
  {==}

def Laws.a_high_impact_development_needs_a_full_document():
  {==}

def Laws.a_warning_is_issued_three_times_for_thirty_days():
  {==}

def Laws.a_terminal_is_trialled_one_month_before_opening():
  {==}

def Laws.a_route_calls_at_its_terminal():
  {==}

def Laws.a_passenger_carries_three_papers():
  {==}

def Laws.a_goods_shipment_carries_two_papers():
  {==}

def Laws.insurance_covers_four_things():
  {==}

def Laws.a_statute_carries_no_copyright():
  {==}

def Laws.five_kinds_of_work_are_exempt():
  {==}

def Laws.copyright_lasts_seventy_years_after_the_author():
  {==}

def Laws.a_legal_entity_gets_fifty_years():
  {==}

def Laws.applied_art_gets_twenty_five_years():
  {==}

def Laws.an_unknown_author_gets_fifty_years():
  {==}

def Laws.traditional_culture_has_no_term():
  {==}

def Laws.the_longest_term_is_seventy_years():
  {==}
