# lajur — the driving model the game runs on.
#
# The street, the traffic, the speed ceiling and the verdict are all decided
# here; PROOF.bend proves the claims that matter. TypeScript draws the result.
#
# The map follows the pattern used by endless driving games: the road is a pure
# function of arc length, its curvature (and direction) sampled from 1-D value
# noise with a smoothstep ease, then integrated. Any stretch can be asked for by
# index alone, so the renderer streams it and never owns a copy.
#
# Units are integers so the proofs have something to hold:
#   distance  centimetres       speed  centimetres per second
#   time      ticks of 1/60 s   gap    centimetres ahead of the player
#   curvature centidegrees per metre
import Base
import ../../bend/model.bend as M
import ../../bend/rules.bend as R

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

type Curve is Data:
  Curve{rate: U32, left: Bool}

# A stretch is streamed as one unit. Fifty metres is short enough to build in a
# frame and long enough that crossings are rare.
def chunk_cm() -> U32:
  5000

# Curvature lattice: one control value every 30 m, eased between them.
def lattice_cm() -> U32:
  3000

# A cheap integer hash. Everything random in the model is a function of an index
# and the seed, so nothing has to be carried or reproduced.
def mix(id: U32, tick: U32) -> U32:
  U32.add(U32.mul(U32.add(id, 1), 2654435761), U32.mul(tick, 40503))

# One lattice value, 0..999.
def noise(cell: U32, seed: U32) -> U32:
  U32.mod(mix(cell, seed), 1000)

# The ease curve that makes value noise look like a road instead of a zigzag.
def ease(+frac: U32) -> U32:
  +square = U32.div(U32.mul(frac, frac), 1000)
  +cube = U32.div(U32.mul(square, frac), 1000)
  U32.sub(U32.mul(3, square), U32.mul(2, cube))

def blend(up: Bool, +a: U32, +b: U32, +s: U32) -> U32:
  match up:
    case True{}:
      U32.add(a, U32.div(U32.mul(U32.sub(b, a), s), 1000))
    case False{}:
      U32.sub(a, U32.div(U32.mul(U32.sub(a, b), s), 1000))

# The noise value at a distance along the road, 0..999. Values above 500 bend to
# the right, below to the left, so the road crosses straight on the way past.
def curve_value(+cm: U32, +seed: U32) -> U32:
  +cell = U32.div(cm, lattice_cm())
  +frac = U32.div(U32.mul(U32.mod(cm, lattice_cm()), 1000), lattice_cm())
  +a = noise(cell, seed)
  +b = noise(U32.add(cell, 1), seed)
  blend(U32.is_le(a, b), a, b, ease(frac))

def rate_of(over: Bool, v: U32) -> U32:
  match over:
    case True{}:
      U32.div(U32.mul(U32.sub(v, 500), 120), 500)
    case False{}:
      U32.div(U32.mul(U32.sub(500, v), 120), 500)

def curve_at(+cm: U32, +seed: U32) -> Curve:
  +v = curve_value(cm, seed)
  Curve{rate_of(U32.is_le(500, v), v), U32.is_lt(v, 500)}

# Walking the road: `index` names the stretched metre-mark, `along` the
# centimetres into it. A tick covers under a metre, so one boundary is all it
# can cross.
def crossed(over: Bool, index: U32, along: U32) -> U32 & U32:
  match over:
    case True{}:
      (U32.add(index, 1), U32.sub(along, chunk_cm()))
    case False{}:
      (index, along)

def walked(+index: U32, +along: U32) -> U32 & U32:
  crossed(U32.is_le(chunk_cm(), along), index, along)

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
def player_next(p: Player, +held: Controls, +input: Controls) -> Player:
  match p:
    case Player{+lane, speed, signal, lamp, +moving, target}:
      +idle = U32.is_eq(moving, 0)
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
      Player{arriving(travel(moving2, lane, target2)), speed2, signalled, lamp2,
             after_travel(travel(moving2, lane, target2)), target2}

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
        held: Controls, residual: U32, index: U32, along: U32, seed: U32}

def is_crashed(s: Status) -> Bool:
  match s:
    case Driving{}:
      False{}
    case Crashed{}:
      True{}

def player_of(w: World) -> Player:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      player

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
        0, M.Urban{}, Nil{}, Driving{},
        Controls{False{}, False{}, False{}, False{}}, 0, 24, 0, 20261024}

# The player advances along the road; `walked` rolls over chunk boundaries and
# answers the new (index, along).
def moved(index: U32, along: U32, +dist: U32) -> U32 & U32:
  walked(index, U32.add(along, dist))

def assemble(pos: U32 & U32, tick: U32, player: Player, traffic: List<&2, Car>,
             oncoming: List<&2, Car>, distance: U32, +zone: M.Zone,
             charges: List<&2, U32>, status: Status, held: Controls,
             residual: U32, seed: U32) -> World:
  match pos:
    case (index, along):
      World{tick, player, traffic, oncoming, distance, zone, charges, status,
            held, residual, index, along, seed}

def step(frozen: Bool, +tick: U32, player: Player, traffic: List<&2, Car>,
         oncoming: List<&2, Car>, distance: U32, +zone: M.Zone,
         charges: List<&2, U32>, held: Controls, residual: U32,
         index: U32, along: U32, +seed: U32, +input: Controls) -> World:
  match frozen:
    case True{}:
      World{tick, player, traffic, oncoming, distance, zone, charges, Crashed{},
            held, residual, index, along, seed}
    case False{}:
      +player2 = player_next(player, held, input)
      +dist = roll(speed_of(player2))
      +traffic2 = drift(traffic, dist, U32.add(tick, 1))
      +oncoming2 = drift_oncoming(oncoming, dist, U32.add(tick, 1))
      +hit = blocked(traffic2, lane_of(player2))
      assemble(moved(index, along, dist), U32.add(tick, 1), player2, traffic2,
               oncoming2, U32.add(distance, dist), zone,
               spread(R.charges(scenario_among(player2, traffic2, zone, hit))), status_after(hit),
               input, residual, seed)

def tick(w: World, input: Controls) -> World:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      step(is_crashed(status), tick, player, traffic, oncoming, distance, zone,
           charges, held, residual, index, along, seed, input)

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
               held, residual, index, along, seed}:
      +total = U32.add(residual, U32.min(ms, 250))
      +count = U32.min(U32.div(U32.mul(total, 60), 1000), 5)
      +left = U32.sub(total, U32.div(U32.mul(count, 1000), 60))
      +spent = run(U32.to_nat(count), World{tick, player, traffic, oncoming, distance,
                                        zone, charges, status, held, left, index,
                                        along, seed}, input)
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
               held, residual, index, along, seed}:
      zone

def limit_kmh(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      kmh(limit_of(zone))

def metres(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      U32.div(distance, 100)

def crashed(w: World) -> Bool:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      is_crashed(status)

def signal_state(w: World) -> Signal:
  signal_of(player_of(w))

def lane_move(w: World) -> U32:
  moving_of(player_of(w))

def lane_target(w: World) -> Lane:
  target_of(player_of(w))

def lane_centre(w: World) -> U32:
  lane_offset(lane_of(player_of(w)))

def traffic_of(w: World) -> List<&2, Car>:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      traffic

def index_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      index

def along_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      along

def seed_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      seed

def curve_rate_of(c: Curve) -> U32:
  match c:
    case Curve{rate, left}:
      rate

def curve_left_of(c: Curve) -> Bool:
  match c:
    case Curve{rate, left}:
      left

def curve_rate(+cm: U32, +seed: U32) -> U32:
  curve_rate_of(curve_at(cm, seed))

def curve_left(+cm: U32, +seed: U32) -> Bool:
  curve_left_of(curve_at(cm, seed))

def curve_of(w: World) -> Curve:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, index, along, seed}:
      curve_at(U32.add(U32.mul(index, chunk_cm()), along), seed)

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
