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
       roundabout: Bool, priority_user: PriorityUser, goods_route_ok: Bool}

# Pasal 134 huruf a to g: the users who take priority, in the order the article
# lists them.
type PriorityUser is Data:
  NoPriority{}
  Fire{}
  Ambulance{}
  Rescue{}
  StateLeader{}
  ForeignGuest{}
  Funeral{}
  Convoy{}

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

# The action a mandatory-direction sign asks for, and the extra facts a sign
# rule reads that the rest of the scenario does not carry.
type Turn is Data:
  NoTurn{}
  TurnLeft{}
  TurnRight{}
  TurnBack{}

# Which of the lanes in the direction of travel, Pasal 108 ayat (3) and (4).
type Lane is Data:
  LaneLeft{}
  LaneRight{}

# Pasal 116 ayat (2): the grounds that ask a driver to slow down.
type Hazard is Data:
  NoHazard{}
  PassingBus{}
  AnimalDrawn{}
  Rain{}
  Community{}
  JunctionAhead{}
  PedestrianCrossing{}

# The act: the posted duty, the manoeuvre, and the facts a single rule reads
# that the six records do not carry.
type Act is Data:
  Act{sign: M.Duty, turn: Turn, parking: Bool, lane_ok: Bool, chains: Bool,
      following_m: U32, v_width: U32, v_length: U32, v_height: U32, v_axle: U32,
      lane: Lane, faster: Bool, sight_clear: Bool, room_ok: Bool,
      train_coming: Bool, crossing_traffic: Bool, yields_to_crossing: Bool,
      left_turn_allowed: Bool, hazard: Hazard, bus_stopping: Bool,
      towing: Bool, towing_ok: Bool, parking_in_line: Bool, collision: Bool}

type Scenario is Data:
  Scenario{road: Road, load: Payload, gear: Equipment, move: Motion, yield: Priority, docs: Papers, act: Act}

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
  , Rule{29, General{}, 1, 0, 250000, 106, 4, 287, 3}
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
  , Rule{39, General{}, 12, 0, 24000000, 50, 1, 277, 0}
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
    # 51-52: the lane within the direction of travel
  , Rule{51, General{}, 0, 0, 0, 108, 3, 0, 0}
  , Rule{52, General{}, 0, 0, 0, 108, 4, 0, 0}
    # 53-54: a left turn at a signal, and a crossing already in use
  , Rule{53, Signal{}, 0, 0, 0, 112, 3, 0, 0}
  , Rule{54, Signal{}, 0, 0, 0, 114, 0, 0, 0}
    # 55-56: the grounds to slow, and a bus taking passengers
  , Rule{55, General{}, 0, 0, 0, 116, 2, 0, 0}
  , Rule{56, General{}, 0, 0, 0, 119, 0, 0, 0}
    # 57-58: the manner of towing, and the manner of parking
  , Rule{57, General{}, 1, 0, 250000, 106, 4, 287, 6}
  , Rule{58, General{}, 0, 0, 0, 120, 0, 0, 0}
    # 59: a collision the driver's negligence caused, Pasal 310 ayat (1)
  , Rule{59, General{}, 6, 0, 1000000, 310, 1, 310, 1}
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

# Pasal 103 and 104 ayat (3): an officer's direction outranks a signal, a sign
# and a marking. It settles them only when the driver obeys it; a driver who
# disobeys is charged with rule 6 and with what the officer overrode.
def officer_wins(directs: Bool, obeys: Bool) -> Bool:
  Bool.and(directs, obeys)

def has_priority(u: PriorityUser) -> Bool:
  match u:
    case NoPriority{}:
      False{}
    case _:
      True{}

# The order of Pasal 134, counted from huruf a.
def priority_rank(u: PriorityUser) -> U32:
  match u:
    case NoPriority{}:
      0
    case Fire{}:
      1
    case Ambulance{}:
      2
    case Rescue{}:
      3
    case StateLeader{}:
      4
    case ForeignGuest{}:
      5
    case Funeral{}:
      6
    case Convoy{}:
      7

# No user outranks a plain road: an absent priority vehicle takes nothing.
def outranks(+a: PriorityUser, +b: PriorityUser) -> Bool:
  Bool.and(has_priority(a), Bool.and(has_priority(b), U32.is_lt(priority_rank(a), priority_rank(b))))

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

# Pasal 121 ayat (2): a motorcycle without a sidecar is not required to set out
# a triangle or a hazard lamp, so rule 27 does not reach it.
def no_triangle_needed(v: Vehicle, sidecar: Bool) -> Bool:
  Bool.and(is_motorcycle(v), Bool.not(sidecar))

# Pasal 118: a vehicle may stop anywhere except where a sign or a solid line
# forbids it, in a place that endangers other users, or on a toll road. Rule 29
# reads the answer, not the reasons.
def stopping_allowed(toll: Bool, forbidden: Bool, endangers: Bool) -> Bool:
  Bool.and(Bool.not(toll), Bool.and(Bool.not(forbidden), Bool.not(endangers)))

# ---------------------------------------------------------------------------
# What a posted sign requires
#
# A duty is a rule, not a caption: NoStopping fires when the driver stops,
# NoLeftTurn when the driver turns left, MaxSpeed when the driver exceeds the
# posted number. A limit of 0 means the sign states the value on the leaf and
# the model does not carry it.
# ---------------------------------------------------------------------------

def turn_is_left(t: Turn) -> Bool:
  match t:
    case TurnLeft{}:
      True{}
    case _:
      False{}

def turn_is_right(t: Turn) -> Bool:
  match t:
    case TurnRight{}:
      True{}
    case _:
      False{}

def turn_is_back(t: Turn) -> Bool:
  match t:
    case TurnBack{}:
      True{}
    case _:
      False{}

def turn_is_straight(t: Turn) -> Bool:
  match t:
    case NoTurn{}:
      True{}
    case _:
      False{}

def lane_is_right(l: Lane) -> Bool:
  match l:
    case LaneLeft{}:
      False{}
    case LaneRight{}:
      True{}

# Pasal 108 ayat (3): the classes the article names as belonging to the left
# lane. A bus is slow too, but the article does not name it.
def keeps_left(v: Vehicle) -> Bool:
  match v:
    case Motorcycle{}:
      True{}
    case Truck{}:
      True{}
    case Bicycle{}:
      True{}
    case Car{}:
      False{}
    case Bus{}:
      False{}

# Pasal 108 ayat (4): the right lane serves a pass, a right turn or a U-turn.
def right_lane_ground(overtaking: Bool, +t: Turn) -> Bool:
  Bool.or(overtaking, Bool.or(turn_is_right(t), turn_is_back(t)))

# Pasal 116 ayat (2) names the grounds; an empty road names none.
def stated_hazard(h: Hazard) -> Bool:
  match h:
    case NoHazard{}:
      False{}
    case _:
      True{}

# Pasal 109 ayat (1): a pass needs a clear sight line and enough room.
def pass_is_safe(act: Act) -> Bool:
  match act:
    case Act{+sign, +turn, +parking, +lane_ok, +chains, +following_m, +v_width, +v_length,
             +v_height, +v_axle, +lane, +faster, +sight_clear, +room_ok, +train_coming, +crossing_traffic,
             +yields_to_crossing, +left_turn_allowed, +hazard, +bus_stopping, +towing, +towing_ok,
             +parking_in_line, +collision}:
      Bool.and(sight_clear, room_ok)

def over_tonnes_if(zero: Bool, limit: U32, kg: U32) -> Bool:
  match zero:
    case True{}:
      False{}
    case False{}:
      U32.is_lt(U32.mul(limit, 1000), kg)

def over_tonnes(+limit: U32, kg: U32) -> Bool:
  over_tonnes_if(U32.is_zero(limit), limit, kg)

def over_metres_if(zero: Bool, limit: U32, mm: U32) -> Bool:
  match zero:
    case True{}:
      False{}
    case False{}:
      U32.is_lt(U32.mul(limit, 1000), mm)

def over_metres(+limit: U32, mm: U32) -> Bool:
  over_metres_if(U32.is_zero(limit), limit, mm)

def over_speed_if(zero: Bool, limit: U32, speed: U32) -> Bool:
  match zero:
    case True{}:
      False{}
    case False{}:
      U32.is_lt(limit, speed)

def over_speed(+limit: U32, speed: U32) -> Bool:
  over_speed_if(U32.is_zero(limit), limit, speed)

def close_following_if(zero: Bool, metres: U32, actual: U32) -> Bool:
  match zero:
    case True{}:
      False{}
    case False{}:
      U32.is_lt(actual, metres)

def close_following(+metres: U32, actual: U32) -> Bool:
  close_following_if(U32.is_zero(metres), metres, actual)

def subject_tag(s: M.Subject) -> U32:
  match s:
    case M.Any{}:
      0
    case M.Motorcycle{}:
      1
    case M.Car{}:
      2
    case M.Truck{}:
      3
    case M.Bus{}:
      4
    case M.Public{}:
      5
    case M.Special{}:
      6
    case M.Trailer{}:
      7
    case M.ThreeWheel{}:
      8
    case M.Bicycle{}:
      9
    case M.Pedestrian{}:
      10
    case M.Cart{}:
      11
    case M.Becak{}:
      12
    case M.Pedati{}:
      13
    case M.Delman{}:
      14
    case M.HorseRider{}:
      15
    case M.NonMotorized{}:
      16

# A bicycle is the one non-motorized vehicle the scenario can carry, and a
# public motor vehicle is the bus.
def subject_bans_tag(v: Vehicle, +tag: U32) -> Bool:
  match v:
    case Motorcycle{}:
      U32.is_eq(tag, 1)
    case Car{}:
      U32.is_eq(tag, 2)
    case Truck{}:
      U32.is_eq(tag, 3)
    case Bus{}:
      Bool.or(U32.is_eq(tag, 4), U32.is_eq(tag, 5))
    case Bicycle{}:
      Bool.or(U32.is_eq(tag, 9), U32.is_eq(tag, 16))

def subject_bans_one(v: Vehicle, s: M.Subject) -> Bool:
  match s:
    case M.Any{}:
      True{}
    case _:
      subject_bans_tag(v, subject_tag(s))

def subject_banned(+v: Vehicle, subjects: List<&2, M.Subject>) -> Bool:
  match subjects:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(subject_bans_one(v, h), subject_banned(v, t))

def lane_violation(v: Vehicle, s: M.Subject, ok: Bool) -> Bool:
  Bool.and(subject_bans_one(v, s), Bool.not(ok))

def sign_violated(act: Act, side: Side, speed: U32, overtaking: Bool, stopping: Bool,
                  emergency_stop: Bool, yields_right: Bool, vehicle: Vehicle, weight: U32) -> Bool:
  match act:
    case Act{+sign, +turn, +parking, +lane_ok, +chains, +following_m, +v_width, +v_length, +v_height, +v_axle, +lane, +faster, +sight_clear, +room_ok, +train_coming, +crossing_traffic,
             +yields_to_crossing, +left_turn_allowed, +hazard, +bus_stopping, +towing, +towing_ok,
             +parking_in_line, +collision}:
      match sign:
        case M.NoDuty{}:
          False{}
        case M.Stop{}:
          Bool.not(stopping)
        case M.GiveWay{}:
          Bool.not(yields_right)
        case M.NoEntry{subjects}:
          subject_banned(vehicle, subjects)
        case M.NoStopping{}:
          Bool.and(Bool.or(stopping, parking), Bool.not(emergency_stop))
        case M.NoParking{}:
          parking
        case M.NoLeftTurn{}:
          turn_is_left(turn)
        case M.NoRightTurn{}:
          turn_is_right(turn)
        case M.NoUTurn{}:
          turn_is_back(turn)
        case M.NoUTurnOrRight{}:
          Bool.or(turn_is_back(turn), turn_is_right(turn))
        case M.NoOvertaking{}:
          overtaking
        case M.NoCloseFollowing{metres}:
          close_following(metres, following_m)
        case M.MaxSpeed{limit}:
          over_speed(limit, speed)
        case M.MinSpeed{limit}:
          U32.is_lt(speed, limit)
        case M.KeepLeft{}:
          side_is_right(side)
        case M.KeepRight{}:
          side_is_left(side)
        case M.TurnLeft{}:
          Bool.not(turn_is_left(turn))
        case M.TurnRight{}:
          Bool.not(turn_is_right(turn))
        case M.GoStraight{}:
          Bool.not(turn_is_straight(turn))
        case M.ChoosePath{}:
          turn_is_back(turn)
        case M.Roundabout{}:
          Bool.not(yields_right)
        case M.UseLane{subject}:
          lane_violation(vehicle, subject, lane_ok)
        case M.UseChains{}:
          Bool.not(chains)
        case M.WeightLimit{limit}:
          over_tonnes(limit, weight)
        case M.AxleLimit{limit}:
          over_tonnes(limit, v_axle)
        case M.LengthLimit{limit}:
          over_metres(limit, v_length)
        case M.HeightLimit{limit}:
          over_metres(limit, v_height)
        case M.WidthLimit{limit}:
          over_metres(limit, v_width)
        case M.DimensionLimit{width, length, height, axle}:
          Bool.or(U32.is_lt(width, v_width),
          Bool.or(U32.is_lt(length, v_length),
          Bool.or(U32.is_lt(height, v_height), U32.is_lt(U32.mul(axle, 1000), v_axle))))
        case M.EndOfRestriction{}:
          False{}

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
    case Scenario{road, load, gear, move, yield, docs, +act}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +priority_user, +goods_route_ok} = road
      Payload{+vehicle, +weight, +cc, +passengers, +sidecar, +overloaded, +carries_people_in_truck, +special_goods, +special_goods_ok} = load
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn, +changing_lane, +indicates_lane, +racing, +slowing, +indicates_slow, +stopping, +parked_ok, +emergency_stop, +emergency_sign, +leaves_accident, +modified} = move
      Priority{+oncoming, +oncoming_room, +grade, +yields_to_uphill, +pedestrian_waiting, +yields_to_pedestrian, +yields_to_emergency, +at_junction, +yields_right} = yield
      +settled = officer_wins(police_directs, obeys_officer)
      pick([
        Bool.and(side_is_right(side), Bool.and(Bool.not(overtaking), Bool.not(settled))),
        Bool.and(overtaking, Bool.or(side_is_left(overtake_side), Bool.not(pass_is_safe(act)))),
        Bool.and(overtaking, front_signals_right),
        Bool.and(oncoming, Bool.not(oncoming_room)),
        Bool.and(grade_is_downhill(grade), Bool.not(yields_to_uphill)),
        Bool.and(police_directs, Bool.not(obeys_officer)),
        Bool.and(signal_red, Bool.not(settled)),
        Bool.and(Bool.or(sign_forbids, sign_violated(act, side, speed, overtaking, stopping, emergency_stop, yields_right, vehicle, weight)), Bool.not(settled)),
        Bool.and(marking_forbids, Bool.not(settled)),
      ], 1)

def charges_driver(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs, +act}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +priority_user, +goods_route_ok} = road
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
        Bool.and(car_like, Bool.and(Bool.not(cabin), Bool.or(Bool.not(seatbelt), Bool.not(rider_helmet)))),
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
    case Scenario{road, load, gear, move, yield, docs, +act}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +priority_user, +goods_route_ok} = road
      Payload{+vehicle, +weight, +cc, +passengers, +sidecar, +overloaded, +carries_people_in_truck, +special_goods, +special_goods_ok} = load
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn, +changing_lane, +indicates_lane, +racing, +slowing, +indicates_slow, +stopping, +parked_ok, +emergency_stop, +emergency_sign, +leaves_accident, +modified} = move
      Priority{+oncoming, +oncoming_room, +grade, +yields_to_uphill, +pedestrian_waiting, +yields_to_pedestrian, +yields_to_emergency, +at_junction, +yields_right} = yield
      Act{+sign, +turn, +parking, +lane_ok, +chains, +following_m, +v_width, +v_length, +v_height, +v_axle, +lane, +faster, +sight_clear, +room_ok, +train_coming, +crossing_traffic, +yields_to_crossing, +left_turn_allowed, +hazard, +bus_stopping, +towing, +towing_ok, +parking_in_line, +collision} = act
      pick([
        Bool.and(railway_crossing, Bool.or(crossing_closed, train_coming)),
        racing,
        Bool.and(emergency_stop, Bool.and(Bool.not(emergency_sign), Bool.not(no_triangle_needed(vehicle, sidecar)))),
        leaves_accident,
        Bool.and(stopping, Bool.not(parked_ok)),
        Bool.and(slowing, Bool.not(indicates_slow)),
        Bool.and(at_junction, Bool.and(Bool.not(roundabout), Bool.not(yields_right))),
        Bool.and(roundabout, Bool.not(yields_right)),
      ], 25)

def charges_vehicle(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs, +act}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +priority_user, +goods_route_ok} = road
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
    case Scenario{road, load, gear, move, yield, docs, +act}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +priority_user, +goods_route_ok} = road
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
        Bool.and(has_priority(priority_user), Bool.not(yields_to_emergency)),
      ], 41)

# ---------------------------------------------------------------------------
# 51-52: which lane within the direction of travel, Pasal 108 ayat (3) and (4).
# A right turn, a U-turn and a pass are the grounds the article allows; the
# lane is charged only when none of them is why the vehicle is there.
# ---------------------------------------------------------------------------
def charges_position(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs, +act}:
      Road{+zone, +side, +police_directs, +obeys_officer, +signal_red, +sign_forbids, +marking_forbids, +railway_crossing, +crossing_closed, +roundabout, +priority_user, +goods_route_ok} = road
      Payload{+vehicle, +weight, +cc, +passengers, +sidecar, +overloaded, +carries_people_in_truck, +special_goods, +special_goods_ok} = load
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn, +changing_lane, +indicates_lane, +racing, +slowing, +indicates_slow, +stopping, +parked_ok, +emergency_stop, +emergency_sign, +leaves_accident, +modified} = move
      Act{+sign, +turn, +parking, +lane_ok, +chains, +following_m, +v_width, +v_length, +v_height, +v_axle, +lane, +faster, +sight_clear, +room_ok, +train_coming, +crossing_traffic, +yields_to_crossing, +left_turn_allowed, +hazard, +bus_stopping, +towing, +towing_ok, +parking_in_line, +collision} = act
      +right = lane_is_right(lane)
      +free = Bool.not(right_lane_ground(overtaking, turn))
      pick([
        Bool.and(right, Bool.and(keeps_left(vehicle), free)),
        Bool.and(right, Bool.and(Bool.not(faster), free)),
        Bool.and(signal_red, Bool.and(turn_is_left(turn), Bool.not(left_turn_allowed))),
        Bool.and(railway_crossing, Bool.and(crossing_traffic, Bool.not(yields_to_crossing))),
        Bool.and(stated_hazard(hazard), Bool.not(slowing)),
        Bool.and(bus_stopping, Bool.not(stopping)),
        Bool.and(towing, Bool.not(towing_ok)),
        Bool.and(parking, Bool.not(parking_in_line)),
        collision,
      ], 51)

def charges(+s: Scenario) -> List<U32>:
  cat(charges_road(s),
  cat(charges_driver(s),
  cat(charges_event(s),
  cat(charges_vehicle(s),
  cat(charges_service(s),
      charges_position(s))))))

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

# The clean road, in the zone the vehicle is in. The zone is the only thing that
# sets the ceiling, so the verdict reads the number the road reads.
def road_in(zone: M.Zone) -> Road:
  Road{zone, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}}

def clean_road() -> Road:
  road_in(M.Urban{})

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

# No posted sign, no turn, a car-sized vehicle, and every lane and chain duty
# satisfied. A sign scenario changes the one field its rule reads.
def clean_act() -> Act:
  Act{M.NoDuty{}, NoTurn{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500, LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def clean_car() -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), clean_act()}

def bike(passengers: U32, +rider_helmet: Bool, +pillion_helmet: Bool) -> Scenario:
  Scenario{clean_road(),
           Payload{Motorcycle{}, 200, 150, passengers, False{}, False{}, False{}, False{}, True{}},
           Equipment{rider_helmet, pillion_helmet, True{}, False{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, False{}, False{}},
           clean_move(), clean_yield(), clean_docs(), clean_act()}

def car_red_light_phone() -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, True{}, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}},
           clean_load(),
           Equipment{True{}, True{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, True{}, True{}, False{}, False{}},
           clean_move(), clean_yield(), clean_docs(), clean_act()}

def car_speeding() -> Scenario:
  Scenario{Road{M.Residential{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}},
           clean_load(), clean_gear(),
           Motion{45, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}},
           clean_yield(), clean_docs(), clean_act()}

def bike_night_downhill() -> Scenario:
  Scenario{clean_road(),
           Payload{Motorcycle{}, 200, 150, 0, False{}, False{}, False{}, False{}, True{}},
           Equipment{True{}, True{}, True{}, False{}, True{}, False{}, False{}, True{}, True{}, True{}, True{}, False{}, False{}},
           clean_move(),
           Priority{False{}, True{}, Downhill{}, False{}, True{}, False{}, True{}, False{}, True{}},
           clean_docs(), clean_act()}

def car_right_lane() -> Scenario:
  Scenario{Road{M.Urban{}, Right{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}},
           clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), clean_act()}

def car_overtake_left() -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(),
           Motion{50, True{}, Left{}, True{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}},
           clean_yield(), clean_docs(), clean_act()}

def car_turning_no_docs() -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(),
           Motion{30, False{}, Right{}, False{}, True{}, False{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}},
           clean_yield(),
           Papers{False{}, True{}, False{}, True{}, True{}, True{}, True{}, True{}}, clean_act()}
def bike_passengers(p: U32) -> Scenario:
  Scenario{clean_road(),
           Payload{Motorcycle{}, 200, 150, p, False{}, False{}, False{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(), clean_docs(), clean_act()}
def truck_overloaded() -> Scenario:
  Scenario{clean_road(),
           Payload{Truck{}, 8000, 0, 0, False{}, True{}, False{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(), clean_docs(), clean_act()}

def bus_uninsured() -> Scenario:
  Scenario{clean_road(),
           Payload{Bus{}, 9000, 0, 12, False{}, False{}, False{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(),
           Papers{True{}, True{}, True{}, True{}, True{}, True{}, False{}, False{}}, clean_act()}

def truck_carrying_people() -> Scenario:
  Scenario{clean_road(),
           Payload{Truck{}, 8000, 0, 3, False{}, False{}, True{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(), clean_docs(), clean_act()}

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

# Every rule carries the next id, so the catalogue has no gap and no duplicate.
def ids_run(rs: List<Rule>, +next: U32) -> Bool:
  match rs:
    case Nil{}:
      True{}
    case +h <> t:
      match h:
        case Rule{+id, tier, months, days, fine, art, ay, pen_art, pen_ay}:
          Bool.and(U32.is_eq(id, next), ids_run(t, U32.add(next, 1)))

def ids_contiguous() -> Bool:
  ids_run(catalogue(), 1)

# ---------------------------------------------------------------------------
# Builders: one knob per law, so a law can say what changes when it changes.
# ---------------------------------------------------------------------------

def with_road(r: Road) -> Scenario:
  Scenario{r, clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), clean_act()}

def with_load(l: Payload) -> Scenario:
  Scenario{clean_road(), l, clean_gear(), clean_move(), clean_yield(), clean_docs(), clean_act()}

def with_gear(g: Equipment) -> Scenario:
  Scenario{clean_road(), clean_load(), g, clean_move(), clean_yield(), clean_docs(), clean_act()}

def with_move(m: Motion) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), m, clean_yield(), clean_docs(), clean_act()}

def with_priority(p: Priority) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), p, clean_docs(), clean_act()}

def with_docs(d: Papers) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), d, clean_act()}

# Road knobs
def road_side(s: Side) -> Road:
  Road{M.Urban{}, s, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}}

def road_officer(directs: Bool, obeys: Bool) -> Road:
  Road{M.Urban{}, Left{}, directs, obeys, False{}, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}}

def road_signal(red: Bool) -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, red, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}}

def road_sign(blocks: Bool) -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, False{}, blocks, False{}, False{}, False{}, False{}, NoPriority{}, True{}}

def road_marking(blocks: Bool) -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, blocks, False{}, False{}, False{}, NoPriority{}, True{}}

def road_railway(closed: Bool) -> Road:
  Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, True{}, closed, False{}, NoPriority{}, True{}}

# An officer directing traffic, and the one instruction the direction replaces.
def road_officer_signal(obeys: Bool, red: Bool) -> Road:
  Road{M.Urban{}, Left{}, True{}, obeys, red, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}}

def road_officer_sign(obeys: Bool, blocks: Bool) -> Road:
  Road{M.Urban{}, Left{}, True{}, obeys, False{}, blocks, False{}, False{}, False{}, False{}, NoPriority{}, True{}}

def road_officer_marking(obeys: Bool, blocks: Bool) -> Road:
  Road{M.Urban{}, Left{}, True{}, obeys, False{}, False{}, blocks, False{}, False{}, False{}, NoPriority{}, True{}}
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

# Pasal 106 ayat (7): an open four-wheeler asks for a seatbelt and a helmet.
def gear_open_helmet(helmet: Bool) -> Equipment:
  Equipment{helmet, True{}, True{}, False{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, False{}, False{}}

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

# A car stopped, and the three grounds of Pasal 118 that make stopping unlawful.
def zone_for(toll: Bool) -> M.Zone:
  match toll:
    case True{}:
      M.Motorway{}
    case False{}:
      M.Urban{}

def car_stopping(+toll: Bool, forbidden: Bool, endangers: Bool) -> Scenario:
  Scenario{Road{zone_for(toll), Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, NoPriority{}, True{}},
           clean_load(), clean_gear(),
           move_stopping(True{}, stopping_allowed(toll, forbidden, endangers)),
           clean_yield(), clean_docs(), clean_act()}

def move_stop_emergency(on: Bool, sign: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, False{}, True{}, on, sign, False{}, False{}}

# A motorcycle broken down, with or without a sidecar, and with or without the
# hazard sign Pasal 121 ayat (1) asks for.
def bike_stop_emergency(sidecar: Bool, sign: Bool) -> Scenario:
  Scenario{clean_road(),
           Payload{Motorcycle{}, 200, 150, 0, sidecar, False{}, False{}, False{}, True{}},
           clean_gear(), move_stop_emergency(True{}, sign), clean_yield(), clean_docs(), clean_act()}

def move_stopping_emergency(on: Bool, emergency: Bool) -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, True{}, on, True{}, emergency, True{}, False{}, False{}}


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
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, round, NoPriority{}, True{}},
           clean_load(), clean_gear(), clean_move(), pri_junction(at, yields), clean_docs(), clean_act()}

def pri_emergency(yields: Bool) -> Priority:
  Priority{False{}, True{}, Flat{}, True{}, False{}, True{}, yields, False{}, True{}}

# A priority user arrives on the road; the driver answers with a yield.
def with_priority_user(user: PriorityUser, yields: Bool) -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, user, True{}},
           clean_load(), clean_gear(), clean_move(), pri_emergency(yields), clean_docs(), clean_act()}

# Papers knobs
def docs_sim(ok: Bool) -> Papers:
  Papers{ok, True{}, True{}, True{}, True{}, True{}, True{}, True{}}

def docs_stnk(ok: Bool) -> Papers:
  Papers{True{}, True{}, ok, True{}, True{}, True{}, True{}, True{}}

def docs_kir(ok: Bool) -> Papers:
  Papers{True{}, True{}, True{}, ok, True{}, True{}, True{}, True{}}
def with_bike(passengers: U32, rider: Bool, pillion: Bool) -> Scenario:
  Scenario{clean_road(), load_motorcycle(passengers), gear_helmet(rider, pillion),
           clean_move(), clean_yield(), clean_docs(), clean_act()}

def with_bike_technical(ok: Bool) -> Scenario:
  Scenario{clean_road(), load_motorcycle(0),
           Equipment{True{}, True{}, True{}, False{}, False{}, True{}, False{}, ok, True{}, True{}, True{}, False{}, False{}},
           clean_move(), clean_yield(), clean_docs(), clean_act()}

def with_bicycle(holds: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Bicycle{}),
           Equipment{True{}, True{}, True{}, False{}, False{}, True{}, False{}, True{}, True{}, True{}, True{}, False{}, holds},
           clean_move(), clean_yield(), clean_docs(), clean_act()}

def with_truck_route(ok: Bool) -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, NoPriority{}, ok},
           load_vehicle(Truck{}), clean_gear(), clean_move(), clean_yield(), clean_docs(), clean_act()}

def with_truck_manifest(ok: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Truck{}), clean_gear(), clean_move(), clean_yield(),
           Papers{True{}, True{}, True{}, True{}, True{}, ok, True{}, True{}}, clean_act()}

def with_bus_stop(ok: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Bus{}), clean_gear(),
           move_stopping(True{}, ok), clean_yield(), clean_docs(), clean_act()}

def with_bus_terminal(ok: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Bus{}), clean_gear(), clean_move(), clean_yield(),
           Papers{True{}, True{}, True{}, True{}, ok, True{}, True{}, True{}}, clean_act()}

def with_bus_insurance(passengers: Bool, crew: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(Bus{}), clean_gear(), clean_move(), clean_yield(),
           Papers{True{}, True{}, True{}, True{}, True{}, True{}, passengers, crew}, clean_act()}

def with_bike_lights(on: Bool) -> Scenario:
  Scenario{clean_road(), load_motorcycle(0),
           Equipment{True{}, True{}, True{}, False{}, False{}, on, False{}, True{}, True{}, True{}, True{}, False{}, False{}},
           clean_move(), clean_yield(), clean_docs(), clean_act()}

# Sign knobs. Each builder posts one duty and leaves every other action lawful,
# so the verdict isolates the rule the sign states.
def act_sign(d: M.Duty) -> Act:
  Act{d, NoTurn{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500, LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def act_parking(d: M.Duty, on: Bool) -> Act:
  Act{d, NoTurn{}, on, True{}, True{}, 100, 1800, 4500, 1500, 1500, LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def act_turn(d: M.Duty, t: Turn) -> Act:
  Act{d, t, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500, LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def act_chains(d: M.Duty, on: Bool) -> Act:
  Act{d, NoTurn{}, False{}, True{}, on, 100, 1800, 4500, 1500, 1500, LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def act_lane(d: M.Duty, ok: Bool) -> Act:
  Act{d, NoTurn{}, False{}, ok, True{}, 100, 1800, 4500, 1500, 1500, LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def act_following(d: M.Duty, metres: U32) -> Act:
  Act{d, NoTurn{}, False{}, True{}, True{}, metres, 1800, 4500, 1500, 1500, LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def act_size(d: M.Duty, width: U32, length: U32, height: U32, axle: U32) -> Act:
  Act{d, NoTurn{}, False{}, True{}, True{}, 100, width, length, height, axle, LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

# Where the vehicle sits in its direction of travel, why, and what it is about
# to do. Pasal 108 ayat (3) and (4) read the three together.
def act_pass(sight: Bool, room: Bool) -> Act:
  Act{M.NoDuty{}, NoTurn{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500,
      LaneLeft{}, False{}, sight, room, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def act_tow(towing: Bool, ok: Bool) -> Act:
  Act{M.NoDuty{}, NoTurn{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500,
      LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{},
      towing, ok, True{}, False{}}

def act_parked_in_line(ok: Bool) -> Act:
  Act{M.NoDuty{}, NoTurn{}, True{}, True{}, True{}, 100, 1800, 4500, 1500, 1500,
      LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{},
      False{}, True{}, ok, False{}}

def act_hazard(h: Hazard) -> Act:
  Act{M.NoDuty{}, NoTurn{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500,
      LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, h, False{}, False{}, True{}, True{}, False{}}

def act_bus(bus: Bool) -> Act:
  Act{M.NoDuty{}, NoTurn{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500,
      LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, bus, False{}, True{}, True{}, False{}}

def act_left_turn(allowed: Bool) -> Act:
  Act{M.NoDuty{}, TurnLeft{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500,
      LaneLeft{}, False{}, True{}, True{}, False{}, False{}, False{}, allowed, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

def act_crossing(train: Bool, traffic: Bool, yields: Bool) -> Act:
  Act{M.NoDuty{}, NoTurn{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500,
      LaneLeft{}, False{}, True{}, True{}, train, traffic, yields, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

# A clean act in a named lane, which is all the drive needs to state.
def act_in_lane(lane: Lane, faster: Bool, collision: Bool) -> Act:
  Act{M.NoDuty{}, NoTurn{}, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500, lane, faster,
      True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{},
      collision}

def act_position(lane: Lane, faster: Bool, t: Turn) -> Act:
  Act{M.NoDuty{}, t, False{}, True{}, True{}, 100, 1800, 4500, 1500, 1500, lane, faster, True{}, True{}, False{}, False{}, False{}, True{}, NoHazard{}, False{}, False{}, True{}, True{}, False{}}

# A pass on the right, with or without a clear sight line and with or without
# room, so each half of Pasal 109 ayat (1) can be charged on its own.
def overtake_with(sight: Bool, room: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), move_overtake(True{}, Right{}, False{}),
           clean_yield(), clean_docs(), act_pass(sight, room)}

# A vehicle towing another, and whether the manner meets the procedure.
def towing_with(ok: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(),
           act_tow(True{}, ok)}

# A car parked in the road, in line with the traffic or not.
def parked_in_line(ok: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(),
           act_parked_in_line(ok)}

# One hazard from Pasal 116 ayat (2), and whether the driver is slowing for it.
def hazard_ahead(h: Hazard, slowing: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), move_slowing(slowing, True{}),
           clean_yield(), clean_docs(), act_hazard(h)}

# A public vehicle stopped to take passengers, and the driver behind it.
def bus_stopped(bus: Bool, stopping: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), move_stopping(stopping, True{}),
           clean_yield(), clean_docs(), act_bus(bus)}

# A left turn at a red signal, with or without a sign or an arrow that allows it.
# The signal itself is charged as rule 7; Pasal 112 ayat (3) charges the turn.
def red_left_turn(allowed: Bool) -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, True{}, False{}, False{}, False{}, False{},
                False{}, NoPriority{}, True{}},
           clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(),
           act_left_turn(allowed)}

# A level crossing: closed or not, with or without a train, and the vehicle that
# is already on it.
def crossing_with(closed: Bool, train: Bool) -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, True{}, closed,
                False{}, NoPriority{}, True{}},
           clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(),
           act_crossing(train, False{}, True{})}

def crossing_in_use(traffic: Bool, yields: Bool) -> Scenario:
  Scenario{Road{M.Urban{}, Left{}, False{}, True{}, False{}, False{}, False{}, True{}, False{},
                False{}, NoPriority{}, True{}},
           clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(),
           act_crossing(False{}, traffic, yields)}

# A collision the driver caused, which Pasal 310 ayat (1) punishes when the
# damage is to a vehicle or to property.
def collision_after(hit: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(),
           act_in_lane(LaneLeft{}, False{}, hit)}

# One vehicle in one lane, at a speed above or below the traffic beside it, and
# about to turn as stated.
def in_lane(load: Payload, lane: Lane, faster: Bool, t: Turn) -> Scenario:
  Scenario{clean_road(), load, clean_gear(), clean_move(), clean_yield(), clean_docs(),
           act_position(lane, faster, t)}

def sign_car(d: M.Duty) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_sign(d)}

def sign_stopping(d: M.Duty, on: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), move_stopping(on, True{}), clean_yield(), clean_docs(), act_sign(d)}

def sign_stopping_emergency(d: M.Duty, on: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), move_stopping_emergency(on, True{}), clean_yield(), clean_docs(), act_sign(d)}

def sign_parking(d: M.Duty, on: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_parking(d, on)}

def sign_turn(d: M.Duty, t: Turn) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_turn(d, t)}

def sign_speed(d: M.Duty, v: U32) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), move_speed(v), clean_yield(), clean_docs(), act_sign(d)}

def sign_side(d: M.Duty, s: Side) -> Scenario:
  Scenario{road_side(s), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_sign(d)}

def sign_vehicle(d: M.Duty, v: Vehicle) -> Scenario:
  Scenario{clean_road(), load_vehicle(v), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_sign(d)}

def sign_chains(d: M.Duty, on: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_chains(d, on)}

def sign_lane(d: M.Duty, ok: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_lane(d, ok)}

def sign_following(d: M.Duty, metres: U32) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_following(d, metres)}

def sign_size(d: M.Duty, width: U32, length: U32, height: U32, axle: U32) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_size(d, width, length, height, axle)}

def sign_overtaking(d: M.Duty, on: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), move_overtake(on, Right{}, False{}), clean_yield(), clean_docs(), act_sign(d)}

def sign_priority(d: M.Duty, yields: Bool) -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), pri_junction(False{}, yields), clean_docs(), act_sign(d)}

def sign_weight(d: M.Duty, weight: U32) -> Scenario:
  Scenario{clean_road(),
           Payload{Car{}, weight, 0, 0, False{}, False{}, False{}, False{}, True{}},
           clean_gear(), clean_move(), clean_yield(), clean_docs(), act_sign(d)}

def sign_lane_vehicle(d: M.Duty, v: Vehicle, ok: Bool) -> Scenario:
  Scenario{clean_road(), load_vehicle(v), clean_gear(), clean_move(), clean_yield(), clean_docs(), act_lane(d, ok)}

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
