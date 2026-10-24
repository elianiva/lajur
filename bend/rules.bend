# lajur — the executable model of Indonesian traffic law.
#
# The catalogue is data: each rule names the article that imposes the duty and
# the article that punishes breaking it, with the penalty the statute states.
# LAWS.bend states what each rule requires, and PROOF.bend proves it.
#
# The adjudicator returns rule ids only, in ascending order.
import Base
import ./model.bend as M

type Side is Data:
  Left{}
  Right{}

type Grade is Data:
  Flat{}
  Uphill{}
  Downhill{}

# An officer's direction outranks a signal, a signal a sign, a sign a marking,
# and a marking the general rule.
type Tier is Data:
  Officer{}
  Signal{}
  Sign{}
  Marking{}
  General{}

type Vehicle is Data:
  Motorcycle{}
  Car{}
  Truck{}
  Bus{}
  Bicycle{}

type Road is Data:
  Road{zone: M.Zone, side: Side, police_directs: Bool, obeys_officer: Bool, signal_red: Bool,
       sign_forbids: Bool, marking_forbids: Bool, railway_crossing: Bool, crossing_closed: Bool,
       roundabout: Bool, emergency_vehicle: Bool, goods_route_ok: Bool}

type Payload is Data:
  Payload{vehicle: Vehicle, weight: U32, cc: U32, passengers: U32, sidecar: Bool,
          overloaded: Bool, carries_people_in_truck: Bool, special_goods: Bool,
          special_goods_ok: Bool}

type Equipment is Data:
  Equipment{rider_helmet: Bool, passenger_helmet: Bool, seatbelt: Bool, cabin: Bool,
            night: Bool, lights_on: Bool, phone: Bool, technical: Bool, roadworthy: Bool,
            spare_kit: Bool, plate: Bool, interference: Bool, holds_vehicle: Bool}

type Motion is Data:
  Motion{speed: U32, overtaking: Bool, overtake_side: Side, front_signals_right: Bool,
         turning: Bool, indicates_turn: Bool, changing_lane: Bool, indicates_lane: Bool,
         racing: Bool, slowing: Bool, indicates_slow: Bool, stopping: Bool, parked_ok: Bool,
         emergency_stop: Bool, emergency_sign: Bool, leaves_accident: Bool, modified: Bool}

type Priority is Data:
  Priority{oncoming: Bool, oncoming_room: Bool, grade: Grade, yields_to_uphill: Bool,
           pedestrian_waiting: Bool, yields_to_pedestrian: Bool, yields_to_emergency: Bool,
           at_junction: Bool, yields_right: Bool}

type Papers is Data:
  Papers{sim: Bool, sim_fits: Bool, stnk: Bool, kir: Bool, stops_at_terminal: Bool,
         manifest: Bool, passenger_insurance: Bool, crew_insurance: Bool}

type Scenario is Data:
  Scenario{road: Road, load: Payload, gear: Equipment, move: Motion, yield: Priority, docs: Papers}

# ---------------------------------------------------------------------------
# Rule catalogue
#
# `art`/`ay` is the duty; `pen_art`/`pen_ay` is the sanction, or 0 where the
# statute assigns none. months, days and fine repeat the sanction exactly.
# ---------------------------------------------------------------------------

type Rule is Data:
  Rule{id: U32, tier: Tier, months: U32, days: U32, fine: U32,
       art: U32, ay: U32, pen_art: U32, pen_ay: U32}

def catalogue() -> List<Rule>:
  [ # 1-9: position on the road and what the road authority says
    Rule{1, General{}, 0, 0, 0, 108, 1, 0, 0}
  , Rule{2, General{}, 0, 0, 0, 109, 1, 0, 0}
  , Rule{3, General{}, 0, 0, 0, 109, 3, 0, 0}
  , Rule{4, General{}, 0, 0, 0, 110, 1, 0, 0}
  , Rule{5, General{}, 0, 0, 0, 111, 0, 0, 0}
  , Rule{6, Officer{}, 1, 0, 250000, 104, 3, 282, 0}
  , Rule{7, Signal{}, 2, 0, 500000, 106, 4, 287, 2}
  , Rule{8, Sign{}, 2, 0, 500000, 106, 4, 287, 1}
  , Rule{9, Marking{}, 2, 0, 500000, 106, 4, 287, 1}
    # 10-24: what the driver does
  , Rule{10, General{}, 1, 0, 250000, 112, 1, 294, 0}
  , Rule{11, General{}, 1, 0, 250000, 112, 2, 295, 0}
  , Rule{12, General{}, 1, 0, 250000, 106, 8, 291, 1}
  , Rule{13, General{}, 1, 0, 250000, 106, 8, 291, 2}
  , Rule{14, General{}, 1, 0, 250000, 106, 9, 292, 0}
  , Rule{15, General{}, 1, 0, 250000, 106, 6, 289, 0}
  , Rule{16, General{}, 1, 0, 250000, 106, 7, 290, 0}
  , Rule{17, General{}, 3, 0, 750000, 106, 1, 283, 0}
  , Rule{18, General{}, 2, 0, 500000, 106, 2, 284, 0}
  , Rule{19, General{}, 1, 0, 250000, 107, 1, 293, 1}
  , Rule{20, General{}, 0, 15, 100000, 107, 2, 293, 2}
  , Rule{21, Sign{}, 2, 0, 500000, 106, 4, 287, 5}
  , Rule{22, General{}, 1, 0, 250000, 106, 5, 288, 2}
  , Rule{23, General{}, 2, 0, 500000, 106, 5, 288, 1}
  , Rule{24, General{}, 2, 0, 500000, 106, 5, 288, 3}
    # 25-32: events on the road
  , Rule{25, Signal{}, 3, 0, 750000, 114, 0, 296, 0}
  , Rule{26, General{}, 12, 0, 3000000, 115, 0, 297, 0}
  , Rule{27, General{}, 2, 0, 500000, 121, 1, 298, 0}
  , Rule{28, General{}, 36, 0, 75000000, 231, 1, 312, 0}
  , Rule{29, Marking{}, 1, 0, 250000, 120, 0, 287, 3}
  , Rule{30, General{}, 0, 0, 0, 117, 0, 0, 0}
  , Rule{31, General{}, 0, 0, 0, 113, 1, 0, 0}
  , Rule{32, General{}, 0, 0, 0, 113, 2, 0, 0}
    # 33-40: the vehicle's condition
  , Rule{33, General{}, 2, 0, 500000, 68, 1, 280, 0}
  , Rule{34, General{}, 2, 0, 500000, 106, 3, 286, 0}
  , Rule{35, General{}, 1, 0, 250000, 106, 3, 285, 1}
  , Rule{36, General{}, 2, 0, 500000, 106, 3, 285, 2}
  , Rule{37, General{}, 2, 0, 500000, 58, 0, 279, 0}
  , Rule{38, General{}, 1, 0, 250000, 57, 3, 278, 0}
  , Rule{39, General{}, 12, 0, 24000000, 52, 2, 277, 0}
  , Rule{40, General{}, 0, 15, 100000, 122, 1, 299, 0}
    # 41-50: freight, public service, and priority
  , Rule{41, General{}, 1, 0, 250000, 125, 0, 301, 0}
  , Rule{42, General{}, 1, 0, 250000, 126, 0, 302, 0}
  , Rule{43, General{}, 1, 0, 250000, 137, 4, 303, 0}
  , Rule{44, General{}, 2, 0, 500000, 162, 1, 305, 0}
  , Rule{45, General{}, 1, 0, 250000, 168, 1, 306, 0}
  , Rule{46, General{}, 2, 0, 500000, 169, 1, 307, 0}
  , Rule{47, General{}, 1, 0, 250000, 36, 0, 276, 0}
  , Rule{48, General{}, 6, 0, 1500000, 189, 0, 309, 0}
  , Rule{49, General{}, 6, 0, 1500000, 237, 2, 313, 0}
  , Rule{50, General{}, 1, 0, 250000, 134, 0, 287, 4}
  ]

# ---------------------------------------------------------------------------
# Predicates over a scenario
# ---------------------------------------------------------------------------

def push(cond: Bool, id: U32, rest: List<U32>) -> List<U32>:
  match cond:
    case True{}:
      id <> rest
    case False{}:
      rest

def cat(a: List<U32>, b: List<U32>) -> List<U32>:
  match a:
    case Nil{}:
      b
    case h <> t:
      h <> cat(t, b)

def is_motorcycle(v: Vehicle) -> Bool:
  match v:
    case Motorcycle{}:
      True{}
    case Car{}:
      False{}
    case Truck{}:
      False{}
    case Bus{}:
      False{}
    case Bicycle{}:
      False{}

def is_bicycle(v: Vehicle) -> Bool:
  match v:
    case Motorcycle{}:
      False{}
    case Car{}:
      False{}
    case Truck{}:
      False{}
    case Bus{}:
      False{}
    case Bicycle{}:
      True{}

def is_bus(v: Vehicle) -> Bool:
  match v:
    case Bus{}:
      True{}
    case _:
      False{}

def is_truck(v: Vehicle) -> Bool:
  match v:
    case Truck{}:
      True{}
    case _:
      False{}

def is_car_like(v: Vehicle) -> Bool:
  match v:
    case Car{}:
      True{}
    case Truck{}:
      True{}
    case Bus{}:
      True{}
    case Motorcycle{}:
      False{}
    case Bicycle{}:
      False{}

def side_is_left(s: Side) -> Bool:
  match s:
    case Left{}:
      True{}
    case Right{}:
      False{}

def side_is_right(s: Side) -> Bool:
  match s:
    case Left{}:
      False{}
    case Right{}:
      True{}

def grade_is_downhill(g: Grade) -> Bool:
  match g:
    case Flat{}:
      False{}
    case Uphill{}:
      False{}
    case Downhill{}:
      True{}

def exceeded(limit: U32, actual: U32) -> Bool:
  U32.is_lt(limit, actual)

def more_than(count: U32, threshold: U32) -> Bool:
  U32.is_lt(threshold, count)

# ---------------------------------------------------------------------------
# Charges, one group per part of the statute. Ids stay in ascending order
# across the concatenation.
# ---------------------------------------------------------------------------

def pick(bs: List<Bool>, +next: U32) -> List<U32>:
  # Turn a run of booleans into the ids that fired, in order.
  match bs:
    case Nil{}:
      Nil{}
    case h <> t:
      push(h, next, pick(t, (next + 1 : U32)))

def charges_road(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +emergency_vehicle, +goods_route_ok} = road
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn, +changing_lane, +indicates_lane, +racing, +slowing, +indicates_slow, +stopping, +parked_ok, +emergency_stop, +emergency_sign, +leaves_accident, +modified} = move
      Priority{+oncoming, +oncoming_room, +grade, +yields_to_uphill, +pedestrian_waiting, +yields_to_pedestrian, +yields_to_emergency, +at_junction, +yields_right} = yield
      pick([
        Bool.and(side_is_right(side), Bool.and(Bool.not(overtaking), Bool.not(police_directs))),
        Bool.and(overtaking, side_is_left(overtake_side)),
        Bool.and(overtaking, front_signals_right),
        Bool.and(oncoming, Bool.not(oncoming_room)),
        Bool.and(grade_is_downhill(grade), Bool.not(yields_to_uphill)),
        Bool.and(police_directs, Bool.not(obeys_officer)),
        signal_red,
        sign_forbids,
        marking_forbids,
      ], 1)

def charges_driver(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +emergency_vehicle, +goods_route_ok} = road
      Payload{+vehicle, +weight, +cc, +passengers, +sidecar, +overloaded, +carries_people_in_truck, +special_goods, +special_goods_ok} = load
      Equipment{+rider_helmet, +passenger_helmet, +seatbelt, +cabin, +night, +lights_on, +phone, +technical, +roadworthy, +spare_kit, +plate, +interference, +holds_vehicle} = gear
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn, +changing_lane, +indicates_lane, +racing, +slowing, +indicates_slow, +stopping, +parked_ok, +emergency_stop, +emergency_sign, +leaves_accident, +modified} = move
      Priority{+oncoming, +oncoming_room, +grade, +yields_to_uphill, +pedestrian_waiting, +yields_to_pedestrian, +yields_to_emergency, +at_junction, +yields_right} = yield
      Papers{+sim, +sim_fits, +stnk, +kir, +stops_at_terminal, +manifest, +passenger_insurance, +crew_insurance} = docs
      +bike = is_motorcycle(vehicle)
      +car_like = is_car_like(vehicle)
      pick([
        Bool.and(turning, Bool.not(indicates_turn)),
        Bool.and(changing_lane, Bool.not(indicates_lane)),
        Bool.and(bike, Bool.not(rider_helmet)),
        Bool.and(bike, Bool.and(more_than(passengers, 0), Bool.not(passenger_helmet))),
        Bool.and(bike, Bool.and(Bool.not(sidecar), more_than(passengers, 1))),
        Bool.and(car_like, Bool.and(cabin, Bool.not(seatbelt))),
        Bool.and(car_like, Bool.and(Bool.not(cabin), Bool.not(seatbelt))),
        phone,
        Bool.and(pedestrian_waiting, Bool.not(yields_to_pedestrian)),
        Bool.and(night, Bool.not(lights_on)),
        Bool.and(bike, Bool.and(Bool.not(night), Bool.not(lights_on))),
        exceeded(M.speed_limit(zone), speed),
        Bool.not(sim),
        Bool.not(stnk),
        Bool.and(car_like, Bool.not(kir)),
      ], 10)

def charges_event(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +emergency_vehicle, +goods_route_ok} = road
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn, +changing_lane, +indicates_lane, +racing, +slowing, +indicates_slow, +stopping, +parked_ok, +emergency_stop, +emergency_sign, +leaves_accident, +modified} = move
      Priority{+oncoming, +oncoming_room, +grade, +yields_to_uphill, +pedestrian_waiting, +yields_to_pedestrian, +yields_to_emergency, +at_junction, +yields_right} = yield
      pick([
        Bool.and(railway_crossing, crossing_closed),
        racing,
        Bool.and(emergency_stop, Bool.not(emergency_sign)),
        leaves_accident,
        Bool.and(stopping, Bool.not(parked_ok)),
        Bool.and(slowing, Bool.not(indicates_slow)),
        Bool.and(at_junction, Bool.and(Bool.not(roundabout), Bool.not(yields_right))),
        Bool.and(roundabout, Bool.not(yields_right)),
      ], 25)

def charges_vehicle(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +emergency_vehicle, +goods_route_ok} = road
      Payload{+vehicle, +weight, +cc, +passengers, +sidecar, +overloaded, +carries_people_in_truck, +special_goods, +special_goods_ok} = load
      Equipment{+rider_helmet, +passenger_helmet, +seatbelt, +cabin, +night, +lights_on, +phone, +technical, +roadworthy, +spare_kit, +plate, +interference, +holds_vehicle} = gear
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn, +changing_lane, +indicates_lane, +racing, +slowing, +indicates_slow, +stopping, +parked_ok, +emergency_stop, +emergency_sign, +leaves_accident, +modified} = move
      +bike = is_motorcycle(vehicle)
      +car_like = is_car_like(vehicle)
      +bicycle = is_bicycle(vehicle)
      pick([
        Bool.not(plate),
        Bool.and(car_like, Bool.not(roadworthy)),
        Bool.and(bike, Bool.not(technical)),
        Bool.and(car_like, Bool.not(technical)),
        interference,
        Bool.and(car_like, Bool.not(spare_kit)),
        modified,
        holds_vehicle,
      ], 33)

def charges_service(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +emergency_vehicle, +goods_route_ok} = road
      Payload{+vehicle, +weight, +cc, +passengers, +sidecar, +overloaded, +carries_people_in_truck, +special_goods, +special_goods_ok} = load
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn, +changing_lane, +indicates_lane, +racing, +slowing, +indicates_slow, +stopping, +parked_ok, +emergency_stop, +emergency_sign, +leaves_accident, +modified} = move
      Priority{+oncoming, +oncoming_room, +grade, +yields_to_uphill, +pedestrian_waiting, +yields_to_pedestrian, +yields_to_emergency, +at_junction, +yields_right} = yield
      Papers{+sim, +sim_fits, +stnk, +kir, +stops_at_terminal, +manifest, +passenger_insurance, +crew_insurance} = docs
      +bus = is_bus(vehicle)
      +truck = is_truck(vehicle)
      pick([
        Bool.and(truck, Bool.not(goods_route_ok)),
        Bool.and(bus, Bool.and(stopping, Bool.not(parked_ok))),
        Bool.and(truck, carries_people_in_truck),
        Bool.and(special_goods, Bool.not(special_goods_ok)),
        Bool.and(truck, Bool.not(manifest)),
        overloaded,
        Bool.and(bus, Bool.not(stops_at_terminal)),
        Bool.and(bus, Bool.not(passenger_insurance)),
        Bool.and(bus, Bool.not(crew_insurance)),
        Bool.and(emergency_vehicle, Bool.not(yields_to_emergency)),
      ], 41)

def charges(+s: Scenario) -> List<U32>:
  cat(charges_road(s),
  cat(charges_driver(s),
  cat(charges_event(s),
  cat(charges_vehicle(s),
      charges_service(s)))))

# ---------------------------------------------------------------------------
# Helpers the laws use
# ---------------------------------------------------------------------------

def contains(+id: U32, ids: List<U32>) -> Bool:
  match ids:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(U32.is_eq(h, id), contains(id, t))

def ids_equal(a: List<U32>, b: List<U32>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case Nil{} _ <> _:
      False{}
    case _ <> _ Nil{}:
      False{}
    case ha <> ta hb <> tb:
      Bool.and(U32.is_eq(ha, hb), ids_equal(ta, tb))

def ascending_from(ids: List<U32>, prev: U32) -> Bool:
  match ids:
    case Nil{}:
      True{}
    case +h <> t:
      Bool.and(U32.is_lt(prev, h), ascending_from(t, h))

def ascending(ids: List<U32>) -> Bool:
  match ids:
    case Nil{}:
      True{}
    case +h <> t:
      ascending_from(t, h)

def Rule.exists(+id: U32, rules: List<Rule>) -> Bool:
  match rules:
    case Nil{}:
      False{}
    case h <> t:
      match h:
        case Rule{+rid, tier, months, days, fine, art, ay, pen_art, pen_ay}:
          Bool.or(U32.is_eq(rid, id), Rule.exists(id, t))

type Sample is Type:
  Sample{name: String, want: List<U32>, got: List<U32>}

def Sample.ok(c: Sample) -> Bool:
  match c:
    case Sample{name, want, got}:
      ids_equal(want, got)

def Sample.passes(cs: List<Sample>) -> Bool:
  match cs:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(Sample.ok(h), Sample.passes(t))

def Sample.sorted(cs: List<Sample>) -> Bool:
  match cs:
    case Nil{}:
      True{}
    case h <> t:
      match h:
        case Sample{name, want, got}:
          Bool.and(ascending(want), Bool.and(ascending(got), Sample.sorted(t)))

def Sample.ids(cs: List<Sample>) -> List<U32>:
  match cs:
    case Nil{}:
      Nil{}
    case h <> t:
      match h:
        case Sample{name, want, got}:
          cat(want, cat(got, Sample.ids(t)))

def all_catalogued(ids: List<U32>) -> Bool:
  match ids:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(Rule.exists(h, catalogue()), all_catalogued(t))

# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------

def clean_road() -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, True{}}

def clean_load() -> Payload:
  Payload{Car{}, 1500, 0, 0, False{}, False{}, False{}, False{}, True{}}

def clean_gear() -> Equipment:
  Equipment{True{}, True{}, True{}, True{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, False{}, False{}}

def clean_move() -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}}

def clean_yield() -> Priority:
  Priority{False{}, True{}, Flat{}, True{}, False{}, True{}, True{}, False{}, True{}}

def clean_docs() -> Papers:
  Papers{True{}, True{}, True{}, True{}, True{}, True{}, True{}, True{}}

def clean_car() -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs()}

def bike(passengers: U32, +rider_helmet: Bool, +pillion_helmet: Bool) -> Scenario:
  Scenario{clean_road(),
           Payload{Motorcycle{}, 200, 150, passengers, False{}, False{}, False{}, False{}, True{}},
           Equipment{rider_helmet, pillion_helmet, True{}, False{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, False{}, False{}},
           clean_move(), clean_yield(), clean_docs()}

def car_red_light_phone() -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, True{}},
           clean_load(),
           Equipment{True{}, True{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, True{}, True{}, False{}, False{}},
           clean_move(), clean_yield(), clean_docs()}

def car_speeding() -> Scenario:
  Scenario{Road{M.Residential{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, True{}},
           clean_load(), clean_gear(),
           Motion{45, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}},
           clean_yield(), clean_docs()}

def bike_night_downhill() -> Scenario:
  Scenario{clean_road(),
           Payload{Motorcycle{}, 200, 150, 0, False{}, False{}, False{}, False{}, True{}},
           Equipment{True{}, True{}, True{}, False{}, True{}, False{}, False{}, True{}, True{}, True{}, True{}, False{}, False{}},
           clean_move(),
           Priority{False{}, True{}, Downhill{}, False{}, True{}, False{}, True{}, False{}, True{}},
           clean_docs()}

def car_right_lane() -> Scenario:
  Scenario{Road{M.Urban{}, Right{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, True{}},
           clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs()}

def car_overtake_left() -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(),
           Motion{50, True{}, Left{}, True{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}},
           clean_yield(), clean_docs()}

def car_turning_no_docs() -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(),
           Motion{30, False{}, Right{}, False{}, True{}, False{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}},
           clean_yield(),
           Papers{False{}, True{}, False{}, True{}, True{}, True{}, True{}, True{}}}
def bike_passengers(p: U32) -> Scenario:
  Scenario{clean_road(),
           Payload{Motorcycle{}, 200, 150, p, False{}, False{}, False{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(), clean_docs()}
def truck_overloaded() -> Scenario:
  Scenario{clean_road(),
           Payload{Truck{}, 8000, 0, 0, False{}, True{}, False{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(), clean_docs()}

def bus_uninsured() -> Scenario:
  Scenario{clean_road(),
           Payload{Bus{}, 9000, 0, 12, False{}, False{}, False{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(),
           Papers{True{}, True{}, True{}, True{}, True{}, True{}, False{}, False{}}}

def truck_carrying_people() -> Scenario:
  Scenario{clean_road(),
           Payload{Truck{}, 8000, 0, 3, False{}, False{}, True{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(), clean_docs()}

def Bool.same(a: Bool, b: Bool) -> Bool:
  match a b:
    case True{} True{}:
      True{}
    case False{} False{}:
      True{}
    case True{} False{}:
      False{}
    case False{} True{}:
      False{}

def passenger_counts_ok() -> Bool:
  Bool.and(Bool.same(contains(14, charges(bike_passengers(0))), False{}),
  Bool.and(Bool.same(contains(14, charges(bike_passengers(1))), False{}),
  Bool.and(Bool.same(contains(14, charges(bike_passengers(2))), True{}),
           Bool.same(contains(14, charges(bike_passengers(3))), True{}))))

# ---------------------------------------------------------------------------
# The golden corpus
# ---------------------------------------------------------------------------

def corpus() -> List<Sample>:
  [ Sample{"clean car", Nil{}, charges(clean_car())}
  , Sample{"bike, no rider helmet", [12], charges(bike(0, False{}, True{}))}
  , Sample{"bike, two passengers, no passenger helmet", [13, 14], charges(bike(2, True{}, False{}))}
  , Sample{"car, red light, phone, no seatbelt", [7, 15, 17], charges(car_red_light_phone())}
  , Sample{"car, 45 in a 30 zone", [21], charges(car_speeding())}
  , Sample{"bike at night, lights off, downhill, pedestrian", [5, 18, 19], charges(bike_night_downhill())}
  , Sample{"car, right lane, not overtaking", [1], charges(car_right_lane())}
  , Sample{"car, overtaking on the left of a right-signalling car", [2, 3], charges(car_overtake_left())}
  , Sample{"car, turning without signal, no SIM, no STNK", [10, 22, 23], charges(car_turning_no_docs())}
  , Sample{"truck, overloaded", [46], charges(truck_overloaded())}
  , Sample{"bus, no passenger or crew insurance", [48, 49], charges(bus_uninsured())}
  , Sample{"truck carrying people", [43], charges(truck_carrying_people())}
  ]

def corpus_passes() -> Bool:
  Sample.passes(corpus())

def corpus_catalogued() -> Bool:
  all_catalogued(Sample.ids(corpus()))

def corpus_sorted() -> Bool:
  Sample.sorted(corpus())

# ---------------------------------------------------------------------------
# Penalty lookup
# ---------------------------------------------------------------------------

def pick_u32(hit: Bool, a: U32, b: U32) -> U32:
  match hit:
    case True{}:
      a
    case False{}:
      b

def months_go(rs: List<Rule>, +id: U32, acc: U32) -> U32:
  match rs:
    case Nil{}:
      acc
    case h <> t:
      match h:
        case Rule{+rid, tier, +months, days, fine, art, ay, pen_art, pen_ay}:
          months_go(t, id, pick_u32(U32.is_eq(rid, id), months, acc))

def days_go(rs: List<Rule>, +id: U32, acc: U32) -> U32:
  match rs:
    case Nil{}:
      acc
    case h <> t:
      match h:
        case Rule{+rid, tier, months, +days, fine, art, ay, pen_art, pen_ay}:
          days_go(t, id, pick_u32(U32.is_eq(rid, id), days, acc))

def fine_go(rs: List<Rule>, +id: U32, acc: U32) -> U32:
  match rs:
    case Nil{}:
      acc
    case h <> t:
      match h:
        case Rule{+rid, tier, months, days, +fine, art, ay, pen_art, pen_ay}:
          fine_go(t, id, pick_u32(U32.is_eq(rid, id), fine, acc))

def article_go(rs: List<Rule>, +id: U32, acc: U32) -> U32:
  match rs:
    case Nil{}:
      acc
    case h <> t:
      match h:
        case Rule{+rid, tier, months, days, fine, +art, ay, pen_art, pen_ay}:
          article_go(t, id, pick_u32(U32.is_eq(rid, id), art, acc))

def sanction_go(rs: List<Rule>, +id: U32, acc: U32) -> U32:
  match rs:
    case Nil{}:
      acc
    case h <> t:
      match h:
        case Rule{+rid, tier, months, days, fine, art, ay, +pen_art, pen_ay}:
          sanction_go(t, id, pick_u32(U32.is_eq(rid, id), pen_art, acc))

def months_of(+id: U32) -> U32:
  months_go(catalogue(), id, 0)

def days_of(+id: U32) -> U32:
  days_go(catalogue(), id, 0)

def fine_of(+id: U32) -> U32:
  fine_go(catalogue(), id, 0)
def count_rules(rs: List<Rule>) -> Nat:
  match rs:
    case Nil{}:
      0n
    case h <> t:
      1n+count_rules(t)

def rule_count() -> Nat:
  count_rules(catalogue())

# ---------------------------------------------------------------------------
# Builders: one knob per law, so a law can say what changes when it changes.
# ---------------------------------------------------------------------------

def with_road(r: Road) -> Scenario:
  Scenario{r, clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs()}

def with_load(l: Payload) -> Scenario:
  Scenario{clean_road(), l, clean_gear(), clean_move(), clean_yield(), clean_docs()}

def with_gear(g: Equipment) -> Scenario:
  Scenario{clean_road(), clean_load(), g, clean_move(), clean_yield(), clean_docs()}

def with_move(m: Motion) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), m, clean_yield(), clean_docs()}

def with_priority(p: Priority) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), p, clean_docs()}

def with_docs(d: Papers) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), d}

# Road knobs
def road_side(s: Side) -> Road:
  Road{M.Urban{}, s, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, True{}}

def road_officer(directs: Bool, obeys: Bool) -> Road:
  Road{M.Urban{}, Left{}, directs, obeys, False{}, False{}, False{}, False{}, False{}, False{}, False{}, True{}}

def road_signal(red: Bool) -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, red, False{}, False{}, False{}, False{}, False{}, False{}, True{}}

def road_sign(blocks: Bool) -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, False{}, blocks, False{}, False{}, False{}, False{}, False{}, True{}}

def road_marking(blocks: Bool) -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, blocks, False{}, False{}, False{}, False{}, True{}}

def road_railway(closed: Bool) -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, True{}, closed, False{}, False{}, True{}}
def load_vehicle(v: Vehicle) -> Payload:
  Payload{v, 1500, 0, 0, False{}, False{}, False{}, False{}, True{}}

def load_motorcycle(passengers: U32) -> Payload:
  Payload{Motorcycle{}, 200, 150, passengers, False{}, False{}, False{}, False{}, True{}}
def load_truck(overloaded: Bool, people: Bool, manifest: Bool) -> Payload:
  Payload{Truck{}, 8000, 0, 0, False{}, overloaded, people, False{}, True{}}

def load_special_goods(ok: Bool) -> Payload:
  Payload{Truck{}, 8000, 0, 0, False{}, False{}, False{}, True{}, ok}

# Equipment knobs
def gear_helmet(rider: Bool, pillion: Bool) -> Equipment:
  Equipment{rider, pillion, True{}, False{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, False{}, False{}}

def gear_seatbelt(belted: Bool, cabin: Bool) -> Equipment:
  Equipment{True{}, True{}, belted, cabin, False{}, True{}, False{}, True{}, True{}, True{}, True{}, False{}, False{}}

def gear_phone(on: Bool) -> Equipment:
  Equipment{True{}, True{}, True{}, True{}, False{}, True{}, on, True{}, True{}, True{}, True{}, False{}, False{}}

def gear_lights(night: Bool, on: Bool) -> Equipment:
  Equipment{True{}, True{}, True{}, True{}, night, on, False{}, True{}, True{}, True{}, True{}, False{}, False{}}

def gear_technical(technical: Bool) -> Equipment:
  Equipment{True{}, True{}, True{}, True{}, False{}, True{}, False{}, technical, True{}, True{}, True{}, False{}, False{}}

def gear_roadworthy(ok: Bool) -> Equipment:
  Equipment{True{}, True{}, True{}, True{}, False{}, True{}, False{}, True{}, ok, True{}, True{}, False{}, False{}}

def gear_spare(ok: Bool) -> Equipment:
  Equipment{True{}, True{}, True{}, True{}, False{}, True{}, False{}, True{}, True{}, ok, True{}, False{}, False{}}

def gear_plate(ok: Bool) -> Equipment:
  Equipment{True{}, True{}, True{}, True{}, False{}, True{}, False{}, True{}, True{}, True{}, ok, False{}, False{}}

def gear_interference(bad: Bool) -> Equipment:
  Equipment{True{}, True{}, True{}, True{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, bad, False{}}
def move_overtake(on: Bool, side: Side, signals_right: Bool) -> Motion:
  Motion{40, on, side, signals_right, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}}

def move_turn(on: Bool, signals: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, on, signals, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}}

def move_lane_change(on: Bool, signals: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, on, signals, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}}

def move_speed(v: U32) -> Motion:
  Motion{v, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}}

def move_racing(on: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, on, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}}

def move_slowing(on: Bool, signals: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, on, signals, False{}, True{}, False{}, False{}, False{}, False{}}

def move_stopping(on: Bool, ok: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, on, ok, False{}, False{}, False{}, False{}}

def move_stop_emergency(on: Bool, sign: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, on, sign, False{}, False{}}

def move_accident(leaves: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, leaves, False{}}

def move_modified(on: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, on}

# Priority knobs
def pri_oncoming(comes: Bool, room: Bool) -> Priority:
  Priority{comes, room, Flat{}, True{}, False{}, True{}, True{}, False{}, True{}}

def pri_downhill(yields: Bool) -> Priority:
  Priority{False{}, True{}, Downhill{}, yields, False{}, True{}, True{}, False{}, True{}}

def pri_pedestrian(waiting: Bool, yields: Bool) -> Priority:
  Priority{False{}, True{}, Flat{}, True{}, waiting, yields, True{}, False{}, True{}}

def pri_junction(at: Bool, yields: Bool) -> Priority:
  Priority{False{}, True{}, Flat{}, True{}, False{}, True{}, True{}, at, yields}

# A junction is both a road shape and a priority question, so this builder sets
# the roundabout flag on the road and the give-way flag on the priority.
def with_junction(at: Bool, round: Bool, yields: Bool) -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, round, False{}, True{}},
           clean_load(), clean_gear(), clean_move(), pri_junction(at, yields), clean_docs()}

def pri_emergency(yields: Bool) -> Priority:
  Priority{False{}, True{}, Flat{}, True{}, False{}, True{}, yields, False{}, True{}}

# The priority vehicle arrives on the road; the driver answers with a yield.
def with_emergency(comes: Bool, yields: Bool) -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, comes, True{}},
           clean_load(), clean_gear(), clean_move(), pri_emergency(yields), clean_docs()}

# Papers knobs
def docs_sim(ok: Bool) -> Papers:
  Papers{ok, True{}, True{}, True{}, True{}, True{}, True{}, True{}}

def docs_stnk(ok: Bool) -> Papers:
  Papers{True{}, True{}, ok, True{}, True{}, True{}, True{}, True{}}

def docs_kir(ok: Bool) -> Papers:
  Papers{True{}, True{}, True{}, ok, True{}, True{}, True{}, True{}}
def with_bike(passengers: U32, rider: Bool, pillion: Bool) -> Scenario:
  Scenario{clean_road(), load_motorcycle(passengers), gear_helmet(rider, pillion),
           clean_move(), clean_yield(), clean_docs()}

def with_bike_technical(ok: Bool) -> Scenario:
  Scenario{clean_road(), load_motorcycle(0),
           Equipment{True{}, True{}, True{}, False{}, False{}, True{}, False{}, ok, True{}, True{}, True{}, False{}, False{}},
           clean_move(), clean_yield(), clean_docs()}

def with_bicycle(holds: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Bicycle{}),
           Equipment{True{}, True{}, True{}, False{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, False{}, holds},
           clean_move(), clean_yield(), clean_docs()}

def with_truck_route(ok: Bool) -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, ok},
           load_vehicle(Truck{}), clean_gear(), clean_move(), clean_yield(), clean_docs()}

def with_truck_manifest(ok: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Truck{}), clean_gear(), clean_move(), clean_yield(),
           Papers{True{}, True{}, True{}, True{}, True{}, ok, True{}, True{}}}

def with_bus_stop(ok: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Bus{}), clean_gear(),
           move_stopping(True{}, ok), clean_yield(), clean_docs()}

def with_bus_terminal(ok: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Bus{}), clean_gear(), clean_move(), clean_yield(),
           Papers{True{}, True{}, True{}, True{}, ok, True{}, True{}, True{}}}

def with_bus_insurance(passengers: Bool, crew: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Bus{}), clean_gear(), clean_move(), clean_yield(),
           Papers{True{}, True{}, True{}, True{}, True{}, True{}, passengers, crew}}

def with_bike_lights(on: Bool) -> Scenario:
  Scenario{clean_road(), load_motorcycle(0),
           Equipment{True{}, True{}, True{}, False{}, False{}, on, False{}, True{}, True{}, True{}, True{}, False{}, False{}},
           clean_move(), clean_yield(), clean_docs()}

# ---------------------------------------------------------------------------
# Precedence and completeness
# ---------------------------------------------------------------------------

def tier_code(t: Tier) -> U32:
  match t:
    case Officer{}:
      0
    case Signal{}:
      1
    case Sign{}:
      2
    case Marking{}:
      3
    case General{}:
      4

def tier_go(rs: List<Rule>, +id: U32, acc: U32) -> U32:
  match rs:
    case Nil{}:
      acc
    case h <> t:
      match h:
        case Rule{+rid, +tier, months, days, fine, art, ay, pen_art, pen_ay}:
          tier_go(t, id, pick_u32(U32.is_eq(rid, id), tier_code(tier), acc))

def tier_of(+id: U32) -> U32:
  tier_go(catalogue(), id, 99)

# The catalogue uses the precedence tiers where the articles demand them.
def tiers_ok() -> Bool:
  Bool.and(U32.is_eq(tier_of(6), 0),
  Bool.and(U32.is_eq(tier_of(7), 1),
  Bool.and(U32.is_eq(tier_of(8), 2),
  Bool.and(U32.is_eq(tier_of(9), 3),
  Bool.and(U32.is_eq(tier_of(25), 1),
  Bool.and(U32.is_eq(tier_of(21), 2),
           U32.is_eq(tier_of(1), 4)))))))

def has_amount_2(days: U32, fine: U32, has: Bool) -> U32:
  match has:
    case True{}:
      1
    case False{}:
      Bool.to_u32(Bool.not(U32.is_zero(fine)))

def has_amount(months: U32, +days: U32, +fine: U32, has: Bool) -> U32:
  match has:
    case True{}:
      1
    case False{}:
      has_amount_2(days, fine, Bool.not(U32.is_zero(days)))

def claimed_without_citation(+months: U32, days: U32, fine: U32) -> U32:
  has_amount(months, days, fine, Bool.not(U32.is_zero(months)))

def has_pen_claim(months: U32, days: U32, fine: U32, pen_art: U32, no_cite: Bool) -> U32:
  match no_cite:
    case True{}:
      claimed_without_citation(months, days, fine)
    case False{}:
      0

def claims_penalty_but_cites_none(+months: U32, days: U32, fine: U32, +pen_art: U32) -> U32:
  has_pen_claim(months, days, fine, pen_art, U32.is_zero(pen_art))

def penal_gap_go(rs: List<Rule>) -> Nat:
  match rs:
    case Nil{}:
      0n
    case h <> t:
      match h:
        case Rule{id, tier, +months, +days, +fine, art, ay, +pen_art, pen_ay}:
          Nat.add(U32.to_nat(claims_penalty_but_cites_none(months, days, fine, pen_art)), penal_gap_go(t))

# A rule that states a penalty names the article that imposes it.
def sanctions_complete() -> Bool:
  Nat.is_eq(penal_gap_go(catalogue()), 0n)


def articles_named_go(rs: List<Rule>) -> Nat:
  match rs:
    case Nil{}:
      0n
    case h <> t:
      match h:
        case Rule{id, tier, months, days, fine, +art, ay, pen_art, pen_ay}:
          Nat.add(U32.to_nat(Bool.to_u32(U32.is_zero(art))), articles_named_go(t))

# A rule with no article cannot be checked against the statute.
def articles_named() -> Bool:
  Nat.is_eq(articles_named_go(catalogue()), 0n)
