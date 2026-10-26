# lajur — the driving model the game runs on.
#
# The street, the traffic, the speed ceiling and the verdict are all decided
# here; PROOF.bend proves the claims that matter. TypeScript draws the result.
#
# The road is the world's (world.bend): the car drives a route along the
# lattice of main roads, one leg per road, and the zone, so the ceiling, is
# the class of the road it is on. Any leg can be asked for by its crossing
# alone, so the renderer streams the town around it and never owns a copy.
#
# Units are integers so the proofs have something to hold:
#   distance  centimetres       speed  centimetres per second
#   time      ticks of 1/60 s   gap    centimetres ahead of the player
#   curvature centidegrees per metre
import Base
import ../../bend/model.bend as M
import ../../bend/rules.bend as R
import ./world.bend as W

# ===========================================================================
# The road
#
# Indonesian arterials are two-way and undivided: two lanes each way, a white
# centre line, no median, and buildings a pavement's width off the kerb.
# ===========================================================================

type Lane is Data:
  Inner{}   # beside the centre line
  Outer{}   # beside the kerb

type Dir is Data:
  Left{}
  Right{}

# A cheap integer hash. Everything random in the model is a function of an index
# and the seed, so nothing has to be carried or reproduced.
def mix(id: U32, tick: U32) -> U32:
  U32.add(U32.mul(U32.add(id, 1), 2654435761), U32.mul(tick, 40503))

# ===========================================================================
# The route
#
# The road the player drives is the world's own. A leg is one road of the
# lattice, from the crossing at (i, j) toward a compass direction: 0 north,
# 1 east, 2 south, 3 west, clockwise as the map is drawn. At the far crossing
# the route takes the next leg, so the town drawn around the car is the town
# the lab shows.
# ===========================================================================

type Leg is Data:
  Leg{i: U32, j: U32, dir: U32, length: U32}

# The lattice names a road by its west or north crossing.
def key_i(+i: U32, +dir: U32) -> U32:
  Bool.pick(U32, U32.is_eq(dir, 3), U32.sub(i, 1), i)

def key_j(+j: U32, +dir: U32) -> U32:
  Bool.pick(U32, U32.is_eq(dir, 0), U32.sub(j, 1), j)

def eastward(+dir: U32) -> Bool:
  Bool.not(U32.is_even(dir))

# The crossing a leg leads to.
def next_i(+i: U32, +dir: U32) -> U32:
  U32.sub(U32.add(i, Bool.to_u32(U32.is_eq(dir, 1))), Bool.to_u32(U32.is_eq(dir, 3)))

def next_j(+j: U32, +dir: U32) -> U32:
  U32.sub(U32.add(j, Bool.to_u32(U32.is_eq(dir, 2))), Bool.to_u32(U32.is_eq(dir, 0)))

def open_road(+seed: U32, +i: U32, +j: U32, +dir: U32) -> Bool:
  W.has_road(seed, key_i(i, dir), key_j(j, dir), eastward(dir))

def class_toward(+i: U32, +j: U32, +dir: U32) -> W.Class:
  W.road_class(key_i(i, dir), key_j(j, dir), eastward(dir))

def leg_from(+seed: U32, +i: U32, +j: U32, +dir: U32) -> Leg:
  Leg{i, j, dir, W.road_length(seed, key_i(i, dir), key_j(j, dir), eastward(dir))}

def leg_length(l: Leg) -> U32:
  match l:
    case Leg{i, j, dir, length}:
      length

def class_on(l: Leg) -> W.Class:
  match l:
    case Leg{i, j, dir, length}:
      class_toward(i, j, dir)

def zone_on(l: Leg) -> M.Zone:
  W.zone_of(class_on(l))

# An arterial has two lanes each way; every other road one.
def wide_on(+l: Leg) -> Bool:
  U32.is_eq(W.class_code(class_on(l)), 1)

# The lattice keeps its crossings at least this far apart.
def shortest_leg() -> U32:
  U32.sub(W.pitch_cm(), U32.mul(W.jitter_cm(), 2))

# A turn: 0 left, 1 straight on, 2 right, 3 back the way the car came.
def turn_to(+dir: U32, +turn: U32) -> U32:
  U32.mod(U32.add(dir, U32.add(turn, 3)), 4)

# Whether a turn's road is there. Back the way the car came is never chosen
# here: it is what is left when nothing else is.
def exit_open(+turn: U32, +lo: Bool, +so: Bool, +ro: Bool) -> Bool:
  Bool.pick(Bool, U32.is_eq(turn, 0), lo,
  Bool.pick(Bool, U32.is_eq(turn, 1), so,
  Bool.pick(Bool, U32.is_eq(turn, 2), ro, False{})))

# Which way to leave a crossing, given which of its roads are there: the turn
# the driver chose if its road is there, else straight on, left, right, and
# back the way the car came only when no other road leaves.
def pick_exit(+want: U32, +lo: Bool, +so: Bool, +ro: Bool) -> U32:
  Bool.pick(U32, exit_open(want, lo, so, ro), want,
  Bool.pick(U32, so, 1,
  Bool.pick(U32, lo, 0,
  Bool.pick(U32, ro, 2, 3))))

def exit_at(+seed: U32, +i: U32, +j: U32, +dir: U32, +want: U32) -> U32:
  +l = turn_to(dir, 0)
  +r = turn_to(dir, 2)
  turn_to(dir, pick_exit(want, open_road(seed, i, j, l), open_road(seed, i, j, dir),
                         open_road(seed, i, j, r)))

# The road the route takes at the far crossing, for the turn the driver chose.
def leg_after(l: Leg, +seed: U32, +turn: U32) -> Leg:
  match l:
    case Leg{+i, +j, +dir, length}:
      +ni = next_i(i, dir)
      +nj = next_j(j, dir)
      leg_from(seed, ni, nj, exit_at(seed, ni, nj, dir, turn))

# Walking the route: `along` is centimetres into the leg. A tick covers under a
# metre and a leg is hundreds, so one crossing is all a tick can pass.
def crossed(over: Bool, +l: Leg, +along: U32, +seed: U32, +turn: U32) -> Leg & U32:
  match over:
    case True{}:
      (leg_after(l, seed, turn), U32.sub(along, leg_length(l)))
    case False{}:
      (l, along)

def walked(+l: Leg, +along: U32, +seed: U32, +turn: U32) -> Leg & U32:
  crossed(U32.is_le(leg_length(l), along), l, along, seed, turn)

# The laws walk every exit a crossing can offer, for every turn asked.
def bit(+k: U32, +b: U32) -> Bool:
  U32.is_eq(U32.mod(U32.div(k, b), 2), 1)

def implies(a: Bool, b: Bool) -> Bool:
  Bool.or(Bool.not(a), b)

def exit_holds(+want: U32, +lo: Bool, +so: Bool, +ro: Bool) -> Bool:
  +r = pick_exit(want, lo, so, ro)
  +any_open = Bool.or(lo, Bool.or(so, ro))
  Bool.and(Bool.or(exit_open(r, lo, so, ro), Bool.not(any_open)),
           implies(exit_open(want, lo, so, ro), U32.is_eq(r, want)))

def exit_holds_at(+k: U32) -> Bool:
  exit_holds(U32.div(k, 8), bit(k, 1), bit(k, 2), bit(k, 4))

def exits_hold(fuel: Nat, +k: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      Bool.and(exit_holds_at(k), exits_hold(p, U32.add(k, 1)))

def every_exit_holds() -> Bool:
  exits_hold(32n, 0)

# ===========================================================================
# Lanes and speed
# ===========================================================================

# Metres from the centre line, in centimetres. The renderer puts the player's
# half of the road on the left, so it subtracts.
def lane_offset(l: Lane) -> U32:
  match l:
    case Inner{}:
      160
    case Outer{}:
      480

# A collector or a lokal street has one lane each way: the car keeps to the
# kerb lane, whose centre is half the way to the kerb of a 4.5 m half road.
def lane_offset_on(wide: Bool, l: Lane) -> U32:
  match wide:
    case True{}:
      lane_offset(l)
    case False{}:
      225

def lane_at(i: U32) -> Lane:
  match i:
    case 0:
      Inner{}
    case _:
      Outer{}

def shift(l: Lane, d: Dir) -> Lane:
  match l:
    case Inner{}:
      match d:
        case Left{}:
          Outer{}
        case Right{}:
          Inner{}
    case Outer{}:
      match d:
        case Left{}:
          Outer{}
        case Right{}:
          Inner{}

def maybe_shift(lane: Lane, moved: Bool, d: Dir) -> Lane:
  match moved:
    case True{}:
      shift(lane, d)
    case False{}:
      lane

def same_lane(a: Lane, b: Lane) -> Bool:
  U32.is_eq(lane_offset(a), lane_offset(b))

# A zone's ceiling, in centimetres per second, from the statute's km/h table.
def limit_of(z: M.Zone) -> U32:
  U32.div(U32.mul(M.speed_limit(z), 100000), 3600)

# The fastest speed any Indonesian road allows, from the statute's own table.
def fastest() -> U32:
  limit_of(M.Motorway{})

def kmh(speed: U32) -> U32:
  U32.div(U32.add(U32.mul(speed, 3600), 50000), 100000)

# Centimetres covered in one 1/60 s tick.
def roll(speed: U32) -> U32:
  U32.div(speed, 60)

def speed_next(speed: U32, up: Bool, down: Bool) -> U32:
  +gain = U32.mul(Bool.to_u32(up), 25)
  +loss = U32.mul(Bool.to_u32(down), 60)
  # Throttle and ceiling first, brake last. The floor is a choice, not a
  # subtraction: U32 wraps, so `sub` before `max` answers 120 km/h for a
  # stopped car.
  +capped = U32.min(U32.add(speed, gain), fastest())
  Bool.pick(U32, U32.is_lt(capped, loss), 0, U32.sub(capped, loss))

# ===========================================================================
# Controls and the player
# ===========================================================================

type Status is Data:
  Driving{}
  Crashed{}

type Signal is Data:
  Off{}
  ToLeft{}
  ToRight{}

type Player is Data:
  Player{lane: Lane, speed: U32, signal: Signal, lamp: U32, moving: U32, target: Lane}

type Controls is Data:
  Controls{left: Bool, right: Bool, up: Bool, down: Bool}

def held_left(c: Controls) -> Bool:
  match c:
    case Controls{left, right, up, down}:
      left

def held_right(c: Controls) -> Bool:
  match c:
    case Controls{left, right, up, down}:
      right

def held_up(c: Controls) -> Bool:
  match c:
    case Controls{left, right, up, down}:
      up

def held_down(c: Controls) -> Bool:
  match c:
    case Controls{left, right, up, down}:
      down

def pressed(now: Bool, before: Bool) -> Bool:
  Bool.and(now, Bool.not(before))

# A lane change is a manoeuvre, not a teleport: twenty-four ticks of moving
# across, with the indicator lit for every one of them. The lamp runs for
# forty-five, so it cannot go out before the car arrives.
def lane_change_ticks() -> U32:
  24

def lamp_ticks() -> U32:
  45

def lamp_after(+lamp: U32, moved: Bool) -> U32:
  match moved:
    case True{}:
      lamp_ticks()
    case False{}:
      Bool.pick(U32, U32.is_eq(lamp, 0), 0, U32.sub(lamp, 1))

def signal_after(moved: Bool, d: Dir, old: Signal) -> Signal:
  match moved:
    case True{}:
      match d:
        case Left{}:
          ToLeft{}
        case Right{}:
          ToRight{}
    case False{}:
      old

def still_on(empty: Bool, s: Signal) -> Signal:
  match empty:
    case True{}:
      Off{}
    case False{}:
      s

def lane_of(p: Player) -> Lane:
  match p:
    case Player{lane, speed, signal, lamp, moving, target}:
      lane

def speed_of(p: Player) -> U32:
  match p:
    case Player{lane, speed, signal, lamp, moving, target}:
      speed

def signal_of(p: Player) -> Signal:
  match p:
    case Player{lane, speed, signal, lamp, moving, target}:
      signal

def moving_of(p: Player) -> U32:
  match p:
    case Player{lane, speed, signal, lamp, moving, target}:
      moving

def target_of(p: Player) -> Lane:
  match p:
    case Player{lane, speed, signal, lamp, moving, target}:
      target

# One tick of the manoeuvre: a car one tick from the end arrives, any other in
# motion keeps its old lane.
def pick_lane(moved: Bool, wanted: Lane, target: Lane) -> Lane:
  match moved:
    case True{}:
      wanted
    case False{}:
      target

# One tick of the manoeuvre: a car one tick from the end arrives, any other in
# motion keeps its old lane, and the count runs down.
def travel_by(last: Bool, +moving: U32, lane: Lane, target: Lane) -> U32 & Lane:
  match last:
    case True{}:
      (0, target)
    case False{}:
      (U32.sub(moving, U32.min(moving, 1)), lane)

def travel(+moving: U32, lane: Lane, target: Lane) -> U32 & Lane:
  travel_by(U32.is_eq(moving, 1), moving, lane, target)

def after_travel(pair: U32 & Lane) -> U32:
  match pair:
    case (left, lane):
      left

def arriving(pair: U32 & Lane) -> Lane:
  match pair:
    case (left, lane):
      lane

# A press starts a change only when the car is not already in one, so a second
# tap cannot skip the manoeuvre the first one began.
def player_next(p: Player, +held: Controls, +input: Controls, +wide: Bool) -> Player:
  match p:
    case Player{+lane, speed, signal, lamp, +moving, target}:
      +idle = Bool.and(U32.is_eq(moving, 0), wide)
      +leftward = Bool.and(pressed(held_left(input), held_left(held)), idle)
      +rightward = Bool.and(Bool.and(pressed(held_right(input), held_right(held)),
                                     Bool.not(leftward)), idle)
      +moved = Bool.or(leftward, rightward)
      +wanted = maybe_shift(maybe_shift(lane, leftward, Left{}), rightward, Right{})
      +target2 = pick_lane(moved, wanted, target)
      +moving2 = Bool.pick(U32, moved, lane_change_ticks(), moving)
      +speed2 = speed_next(speed, held_up(input), held_down(input))
      +lamp2 = lamp_after(lamp, moved)
      +fresh = signal_after(leftward, Left{}, signal_after(rightward, Right{}, signal))
      +signalled = still_on(U32.is_eq(lamp2, 0), fresh)
      # A one-lane road has no lane to change to: the car is in the kerb lane.
      Player{Bool.pick(Lane, wide, arriving(travel(moving2, lane, target2)), Outer{}), speed2,
             signalled, lamp2, Bool.pick(U32, wide, after_travel(travel(moving2, lane, target2)), 0),
             Bool.pick(Lane, wide, target2, Outer{})}

# The player on a one-lane road: in the kerb lane, with no change under way.
def keep_lane(wide: Bool, p: Player) -> Player:
  match wide:
    case True{}:
      p
    case False{}:
      match p:
        case Player{lane, speed, signal, lamp, moving, target}:
          Player{Outer{}, speed, signal, lamp, 0, Outer{}}

def cruising(speed: U32) -> Player:
  Player{Inner{}, speed, Off{}, 0, 0, Inner{}}

# ===========================================================================
# Traffic
# ===========================================================================

type Body is Data:
  Sedan{}
  Hatch{}
  Taxi{}
  Van{}
  Bus{}
  Truck{}
  Bike{}

def body_length(b: Body) -> U32:
  match b:
    case Sedan{}:
      430
    case Hatch{}:
      370
    case Taxi{}:
      430
    case Van{}:
      500
    case Bus{}:
      900
    case Truck{}:
      640
    case Bike{}:
      190

def body_at(i: U32) -> Body:
  match i:
    case 0:
      Sedan{}
    case 1:
      Bike{}
    case 2:
      Van{}
    case 3:
      Bike{}
    case 4:
      Taxi{}
    case 5:
      Hatch{}
    case _:
      Truck{}

type Car is Data:
  Car{id: U32, lane: Lane, gap: U32, speed: U32, body: Body, colour: U32}

def respawn_lane(id: U32, tick: U32) -> Lane:
  lane_at(U32.mod(mix(id, tick), 2))

def respawn_gap(id: U32, tick: U32) -> U32:
  U32.add(7000, U32.mod(U32.div(mix(id, tick), 3), 5000))

def respawn_body(id: U32, tick: U32) -> Body:
  body_at(U32.mod(U32.div(mix(id, tick), 5), 7))

def respawn_colour(id: U32, tick: U32) -> U32:
  U32.mod(U32.div(mix(id, tick), 11), 6)

def respawn_speed(id: U32, tick: U32) -> U32:
  U32.add(550, U32.mod(U32.div(mix(id, tick), 7), 500))

# The gap opens or closes by the difference between the two speeds, and floors
# at zero.
def adjust(z: U32, gain: U32, +loss: U32) -> U32:
  +grown = U32.add(z, gain)
  Bool.pick(U32, U32.is_lt(grown, loss), 0, U32.sub(grown, loss))

# A car that falls 3 m behind comes back ahead with a fresh lane, body and
# colour. `gone` is its own parameter so the checker can split on it.
def place_car(gone: Bool, gap: U32, lane: Lane, speed: U32, body: Body,
              colour: U32, +id: U32, +tick: U32) -> Car:
  match gone:
    case True{}:
      Car{id, respawn_lane(id, tick), respawn_gap(id, tick), respawn_speed(id, tick),
          respawn_body(id, tick), respawn_colour(id, tick)}
    case False{}:
      Car{id, lane, gap, speed, body, colour}

def advance_car(c: Car, travel: U32, tick: U32) -> Car:
  match c:
    case Car{id, lane, gap, +speed, body, colour}:
      +closing = adjust(gap, roll(speed), travel)
      place_car(U32.is_lt(closing, 300), closing, lane, speed, body, colour, id, tick)

# Oncoming traffic closes at the sum of the two speeds.
def advance_oncoming(c: Car, travel: U32, tick: U32) -> Car:
  match c:
    case Car{id, lane, gap, +speed, body, colour}:
      +closing = adjust(gap, 0, U32.add(roll(speed), travel))
      place_car(U32.is_lt(closing, 300), closing, lane, speed, body, colour, id, tick)

def drift(cars: List<&2, Car>, +travel: U32, +tick: U32) -> List<&2, Car>:
  match cars:
    case Nil{}:
      Nil{}
    case h <> t:
      advance_car(h, travel, tick) <> drift(t, travel, tick)

def drift_oncoming(cars: List<&2, Car>, +travel: U32, +tick: U32) -> List<&2, Car>:
  match cars:
    case Nil{}:
      Nil{}
    case h <> t:
      advance_oncoming(h, travel, tick) <> drift_oncoming(t, travel, tick)

def respawn_all(cars: List<&2, Car>, +tick: U32) -> List<&2, Car>:
  match cars:
    case Nil{}:
      Nil{}
    case Car{+id, lane, gap, speed, body, colour} <> t:
      Car{id, respawn_lane(id, tick), respawn_gap(id, tick), respawn_speed(id, tick),
          respawn_body(id, tick), respawn_colour(id, tick)} <> respawn_all(t, tick)

# On a one-lane road every car keeps to the kerb lane.
def keep_left(+wide: Bool, cars: List<&2, Car>) -> List<&2, Car>:
  match cars:
    case Nil{}:
      Nil{}
    case Car{id, lane, gap, speed, body, colour} <> t:
      Car{id, Bool.pick(Lane, wide, lane, Outer{}), gap, speed, body, colour} <> keep_left(wide, t)

# Past a crossing the cars ahead are the new road's: each comes back ahead,
# at least seventy metres off, with a fresh lane, body and colour.
def refresh(fresh: Bool, cars: List<&2, Car>, +tick: U32) -> List<&2, Car>:
  match fresh:
    case True{}:
      respawn_all(cars, tick)
    case False{}:
      cars

# A car is in the way when it shares the lane and its nose is inside the
# player's 4.2 m envelope plus half its own length.
def car_blocks(c: Car, at: Lane) -> Bool:
  match c:
    case Car{id, lane, gap, speed, body, colour}:
      Bool.and(same_lane(lane, at),
               U32.is_lt(gap, U32.add(U32.div(body_length(body), 2), 210)))

def blocked(cars: List<&2, Car>, +at: Lane) -> Bool:
  match cars:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(car_blocks(h, at), blocked(t, at))

# ===========================================================================
# Charging the driver
# ===========================================================================

def spread(ids: List<&1, U32>) -> List<&2, U32>:
  match ids:
    case Nil{}:
      Nil{}
    case h <> t:
      h <> spread(t)

def motion_for(v: U32, changing: Bool, signalling: Bool) -> R.Motion:
  R.Motion{v, False{}, R.Right{}, False{}, False{}, True{}, changing, signalling,
           False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}}

def signalling(s: Signal) -> Bool:
  match s:
    case Off{}:
      False{}
    case ToLeft{}:
      True{}
    case ToRight{}:
      True{}

# The lane the game draws is the lane the statute names: the kerb lane is the
# left lane, and the one beside the centre line is the right.
def lane_use(l: Lane) -> R.Lane:
  match l:
    case Outer{}:
      R.LaneLeft{}
    case Inner{}:
      R.LaneRight{}

# A car in the other lane, close enough to be the traffic the player is moving
# past, and slower than the player. A car in the player's own lane, one further
# off, or one the player is closing on all leave the player faster.
def outruns(c: Car, at: Lane, pace: U32) -> Bool:
  match c:
    case Car{id, lane, gap, +speed, body, colour}:
      Bool.or(same_lane(lane, at),
      Bool.or(Bool.not(U32.is_lt(gap, 4000)), U32.is_lt(speed, pace)))

def outruns_all(+at: Lane, +speed: U32, cars: List<&2, Car>) -> Bool:
  match cars:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(outruns(h, at, speed), outruns_all(at, speed, t))

# Pasal 108 ayat (4): the right lane is for a vehicle moving faster than the
# traffic beside it. With nothing beside it, nothing is slower.
def scenario_among(p: Player, +cars: List<&2, Car>, zone: M.Zone, hit: Bool) -> R.Scenario:
  match p:
    case Player{+lane, +speed, signal, lamp, moving, target}:
      +changing = Bool.or(signalling(signal), Bool.not(U32.is_eq(moving, 0)))
      # A scenario carries the signs in force at the moment; the game posts no
      # sign duty, so it names the clean act apart from the lane facts.
      R.Scenario{R.road_in(zone), R.clean_load(), R.clean_gear(),
                 motion_for(kmh(speed), changing, changing),
                 R.clean_yield(), R.clean_docs(),
                 R.act_in_lane(lane_use(lane), outruns_all(lane, speed, cars), hit)}

# A moment with no traffic beside the player, for the proofs that judge one car.
def scenario_for(p: Player) -> R.Scenario:
  scenario_among(p, Nil{}, M.Urban{}, False{})

# The same moment in a named zone, for the laws about the ceiling.
def scenario_in(p: Player, zone: M.Zone) -> R.Scenario:
  scenario_among(p, Nil{}, zone, False{})

# The same moment after a collision, for the laws about Pasal 310.
def scenario_crash(p: Player, hit: Bool) -> R.Scenario:
  scenario_among(p, Nil{}, M.Urban{}, hit)

def status_after(hit: Bool) -> Status:
  match hit:
    case True{}:
      Crashed{}
    case False{}:
      Driving{}

# ===========================================================================
# The world
# ===========================================================================

type World is Data:
  World{tick: U32, player: Player, traffic: List<&2, Car>, oncoming: List<&2, Car>,
        distance: U32, zone: M.Zone, charges: List<&2, U32>, status: Status,
        held: Controls, residual: U32, leg: Leg, along: U32, turn: U32,
        seed: U32}

def is_crashed(s: Status) -> Bool:
  match s:
    case Driving{}:
      False{}
    case Crashed{}:
      True{}

def player_of(w: World) -> Player:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      player

def start_seed() -> U32:
  20261024

# The arterial east from crossing (1, 0), the first road of every drive.
def start_leg() -> Leg:
  leg_from(start_seed(), 1, 0, 1)

def start() -> World:
  World{0,
        cruising(1000),
        [ Car{1, Outer{}, 3000, 700, Bike{}, 0}
        , Car{2, Inner{}, 6200, 850, Van{}, 3}
        , Car{3, Outer{}, 9000, 800, Taxi{}, 2}
        , Car{4, Inner{}, 12500, 950, Hatch{}, 1}
        , Car{5, Outer{}, 15500, 750, Bike{}, 4}
        ],
        [ Car{11, Inner{}, 4000, 1100, Bus{}, 5}
        , Car{12, Outer{}, 8000, 1200, Sedan{}, 4}
        , Car{13, Inner{}, 13000, 1000, Truck{}, 2}
        ],
        0, zone_on(start_leg()), Nil{}, Driving{},
        Controls{False{}, False{}, False{}, False{}}, 0, start_leg(), 20000, 1,
        start_seed()}

# A driver chooses the turn at a crossing by signalling in the last hundred
# metres before it, and the lamp stays lit until the crossing. A tap further
# back is a lane change and chooses nothing, so overtaking never turns the car
# off its road. With no turn chosen the car goes straight on.
def approach_cm() -> U32:
  10000

def near_crossing(+leg: Leg, +along: U32) -> Bool:
  U32.is_le(leg_length(leg), U32.add(along, approach_cm()))

def turn_by(near: Bool, +left: Bool, +right: Bool, +turn: U32) -> U32:
  match near:
    case True{}:
      Bool.pick(U32, left, 0, Bool.pick(U32, right, 2, turn))
    case False{}:
      turn

def turn_after(+near: Bool, +held: Controls, +input: Controls, +turn: U32) -> U32:
  turn_by(near, pressed(held_left(input), held_left(held)),
          pressed(held_right(input), held_right(held)), turn)

# The player advances along the route; `walked` takes the next leg at a
# crossing and answers the new (leg, along).
def moved(+leg: Leg, along: U32, +dist: U32, +seed: U32, +turn: U32) -> Leg & U32:
  walked(leg, U32.add(along, dist), seed, turn)

# The car has moved to `pos`. The zone is the class of the road it is on, so
# the ceiling changes where the road does. Past a crossing (the car is nearer
# the start of its leg than it was) the traffic is the new road's and the turn
# is spent. On a one-lane road every car keeps to the kerb lane.
def settle(pos: Leg & U32, +tick: U32, player: Player, traffic: List<&2, Car>,
           oncoming: List<&2, Car>, +dist: U32, distance: U32, +input: Controls,
           residual: U32, +was: U32, +turn: U32, seed: U32) -> World:
  match pos:
    case (+leg, +along):
      +passed = U32.is_lt(along, was)
      +wide = wide_on(leg)
      +zone = zone_on(leg)
      +kept = keep_lane(wide, player)
      +traffic2 = keep_left(wide, refresh(passed, drift(traffic, dist, tick), tick))
      +oncoming2 = keep_left(wide, refresh(passed, drift_oncoming(oncoming, dist, tick), tick))
      +hit = blocked(traffic2, lane_of(kept))
      World{tick, kept, traffic2, oncoming2, U32.add(distance, dist), zone,
            spread(R.charges(scenario_among(kept, traffic2, zone, hit))), status_after(hit),
            input, residual, leg, along, Bool.pick(U32, passed, 1, turn), seed}

def step(frozen: Bool, +tick: U32, player: Player, traffic: List<&2, Car>,
         oncoming: List<&2, Car>, distance: U32, zone: M.Zone,
         charges: List<&2, U32>, +held: Controls, residual: U32,
         +leg: Leg, +along: U32, turn: U32, +seed: U32, +input: Controls) -> World:
  match frozen:
    case True{}:
      World{tick, player, traffic, oncoming, distance, zone, charges, Crashed{},
            held, residual, leg, along, turn, seed}
    case False{}:
      +player2 = player_next(player, held, input, wide_on(leg))
      +dist = roll(speed_of(player2))
      +turn2 = turn_after(near_crossing(leg, along), held, input, turn)
      settle(moved(leg, along, dist, seed, turn2), U32.add(tick, 1), player2, traffic,
             oncoming, dist, distance, input, residual, along, turn2, seed)

def tick(w: World, input: Controls) -> World:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      step(is_crashed(status), tick, player, traffic, oncoming, distance, zone,
           charges, held, residual, leg, along, turn, seed, input)

# A Nat fuel counts the ticks down; the shrinking argument comes first.
def run(fuel: Nat, w: World, +input: Controls) -> World:
  match fuel:
    case 0n:
      w
    case 1n+p:
      run(p, tick(w, input), input)

# The frame's milliseconds become whole 1/60 s ticks; the remainder stays in the
# world, so a 144 Hz monitor and a 60 Hz one cover the same ground.
def advance(w: World, ms: U32, input: Controls) -> World:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      +total = U32.add(residual, U32.min(ms, 250))
      +count = U32.min(U32.div(U32.mul(total, 60), 1000), 5)
      +left = U32.sub(total, U32.div(U32.mul(count, 1000), 60))
      +spent = run(U32.to_nat(count), World{tick, player, traffic, oncoming, distance,
                                        zone, charges, status, held, left, leg,
                                        along, turn, seed}, input)
      spent

def restart(w: World) -> World:
  start()

# ===========================================================================
# What the screen reads
# ===========================================================================

def speed_kmh(w: World) -> U32:
  kmh(speed_of(player_of(w)))

def zone_of(w: World) -> M.Zone:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      zone

def limit_kmh(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      kmh(limit_of(zone))

def metres(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      U32.div(distance, 100)

def crashed(w: World) -> Bool:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      is_crashed(status)

# The lamp shows the turn chosen at the crossing ahead, or else the lane change.
def turn_signal(+turn: U32, s: Signal) -> Signal:
  Bool.pick(Signal, U32.is_eq(turn, 0), ToLeft{}, Bool.pick(Signal, U32.is_eq(turn, 2), ToRight{}, s))

def turn_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      turn

def signal_state(+w: World) -> Signal:
  turn_signal(turn_of(w), signal_of(player_of(w)))

def lane_move(w: World) -> U32:
  moving_of(player_of(w))

def lane_target(w: World) -> Lane:
  target_of(player_of(w))

def wide(w: World) -> Bool:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      wide_on(leg)

def lane_centre(+w: World) -> U32:
  lane_offset_on(wide(w), lane_of(player_of(w)))

def traffic_of(w: World) -> List<&2, Car>:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      traffic

def leg_of(w: World) -> Leg:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      leg

def along_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      along

def seed_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, seed}:
      seed

# ===========================================================================
# Citations
# ===========================================================================

def rule_name(id: U32) -> String:
  match id:
    case 1:
      "Left side of the road"
    case 7:
      "Red light"
    case 9:
      "Road marking"
    case 11:
      "Signal before a lane change"
    case 21:
      "Speed limit"
    case 52:
      "Right lane"
    case 59:
      "Negligent collision"
    case _:
      "Road rule"

def rule_art(r: R.Rule) -> U32:
  match r:
    case R.Rule{id, tier, months, days, fine, art, ay, pen_art, pen_ay}:
      art

def rule_ay(r: R.Rule) -> U32:
  match r:
    case R.Rule{id, tier, months, days, fine, art, ay, pen_art, pen_ay}:
      ay

def rule_id(r: R.Rule) -> U32:
  match r:
    case R.Rule{id, tier, months, days, fine, art, ay, pen_art, pen_ay}:
      id

def find_article(rs: List<&1, R.Rule>, +id: U32, acc: U32) -> U32:
  match rs:
    case Nil{}:
      acc
    case +h <> t:
      +found = U32.is_eq(rule_id(h), id)
      find_article(t, id, Bool.pick(U32, found, rule_art(h), acc))

def find_ayat(rs: List<&1, R.Rule>, +id: U32, acc: U32) -> U32:
  match rs:
    case Nil{}:
      acc
    case +h <> t:
      +found = U32.is_eq(rule_id(h), id)
      find_ayat(t, id, Bool.pick(U32, found, rule_ay(h), acc))

def article_of(id: U32) -> U32:
  find_article(R.catalogue(), id, 0)

def ayat_of(id: U32) -> U32:
  find_ayat(R.catalogue(), id, 0)

def fine_of(id: U32) -> U32:
  R.fine_of(id)

def header_of(+id: U32) -> String:
  "Pasal " ++ U32.show(article_of(id)) ++ " ayat (" ++ U32.show(ayat_of(id)) ++ ")"
