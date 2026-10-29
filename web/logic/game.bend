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
import ./lokal.bend as L
import ../../bend/licence.bend as Lic

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

# A collector inside a cell is a leg too: the collector across cell (ci, cj),
# from its parameter t0 to the next place a road meets it, the other
# collector's crossing or the main road at the cell's side. dir 0 or 2 runs
# the collector across u, the way v shrinks or grows; 1 or 3 the one across
# v, the way u grows or shrinks: the compass of the lattice.
type Leg is Data:
  Leg{i: U32, j: U32, dir: U32, length: U32}
  Cut{ci: U32, cj: U32, dir: U32, t0: U32, length: U32}

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
    case Cut{ci, cj, dir, t0, length}:
      length

def class_on(l: Leg) -> W.Class:
  match l:
    case Leg{i, j, dir, length}:
      class_toward(i, j, dir)
    case Cut{ci, cj, dir, t0, length}:
      W.Collector{}

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

# ---- The collectors inside a cell ---------------------------------------------

# Whether dir runs the way the parameter grows: east along u, south along v.
def plus(+dir: U32) -> Bool:
  Bool.or(U32.is_eq(dir, 1), U32.is_eq(dir, 2))

# Where the collector across u (or v) of cell (i, j) sits, or 0 for none.
def cut_on(+seed: U32, +i: U32, +j: U32, +across_u: Bool) -> U32:
  +c = W.cell_cuts(seed, i, j)
  Bool.pick(U32, across_u, W.cuts_u(c), W.cuts_v(c))

# The next place a road meets the collector, from t0 the way dir runs: the
# other collector at x, if there is one ahead, else the cell's side.
def stop_ahead(+t0: U32, +x: U32, +up: Bool) -> U32:
  +has = U32.is_ne(x, 0)
  Bool.pick(U32, up, Bool.pick(U32, Bool.and(has, U32.is_lt(t0, x)), x, 65536),
                     Bool.pick(U32, Bool.and(has, U32.is_lt(x, t0)), x, 0))

def stop_behind(+t: U32, +x: U32, +up: Bool) -> U32:
  +has = U32.is_ne(x, 0)
  Bool.pick(U32, up, Bool.pick(U32, Bool.and(has, U32.is_lt(x, t)), x, 0),
                     Bool.pick(U32, Bool.and(has, U32.is_lt(t, x)), x, 65536))

def span(+a: U32, +b: U32) -> U32:
  U32.sub(U32.max(a, b), U32.min(a, b))

def cut_end(+seed: U32, +ci: U32, +cj: U32, +dir: U32, +t0: U32) -> U32:
  stop_ahead(t0, cut_on(seed, ci, cj, Bool.not(U32.is_even(dir))), plus(dir))

def cut_from(+seed: U32, +ci: U32, +cj: U32, +dir: U32, +t0: U32) -> Leg:
  +eu = U32.is_even(dir)
  +at = cut_on(seed, ci, cj, eu)
  +f = W.frame_of(seed, ci, cj)
  Cut{ci, cj, dir, t0, span(W.frame_to(f, eu, at, t0), W.frame_to(f, eu, at, cut_end(seed, ci, cj, dir, t0)))}

# The collector leg running dir through parameter t, and the centimetres
# into it there.
def cut_through(+seed: U32, +ci: U32, +cj: U32, +dir: U32, +t: U32) -> Leg & U32:
  +eu = U32.is_even(dir)
  +at = cut_on(seed, ci, cj, eu)
  +t0 = stop_behind(t, cut_on(seed, ci, cj, Bool.not(eu)), plus(dir))
  +f = W.frame_of(seed, ci, cj)
  (cut_from(seed, ci, cj, dir, t0), span(W.frame_to(f, eu, at, t0), W.frame_to(f, eu, at, t)))

# The leg along the main road (ki, kj, east) that runs dir, and the
# centimetres into it at `at` from the key crossing.
def road_at(+seed: U32, +ki: U32, +kj: U32, +east: Bool, +at: U32, +dir: U32) -> Leg & U32:
  +up = plus(dir)
  +si = Bool.pick(U32, Bool.and(east, Bool.not(up)), U32.add(ki, 1), ki)
  +sj = Bool.pick(U32, Bool.and(Bool.not(east), Bool.not(up)), U32.add(kj, 1), kj)
  +l2 = leg_from(seed, si, sj, dir)
  +len = leg_length(l2)
  (l2, Bool.pick(U32, up, at, U32.sub(len, U32.min(at, len))))

# At the cell's side the collector meets a main road: the car turns onto it,
# or goes straight on into the next cell's collector where one lines up.
def side_exit(straight: Bool, +seed: U32, +ci: U32, +cj: U32, +dir: U32, +at: U32, +e: U32) -> Leg & U32:
  match straight:
    case True{}:
      (cut_from(seed, next_i(ci, dir), next_j(cj, dir), dir, Bool.pick(U32, plus(dir), 0, 65536)), 0)
    case False{}:
      +eu = U32.is_even(dir)
      +ki = U32.add(ci, Bool.to_u32(U32.is_eq(dir, 1)))
      +kj = U32.add(cj, Bool.to_u32(U32.is_eq(dir, 2)))
      road_at(seed, ki, kj, eu, L.length_to(W.curve_of(seed, ki, kj, eu), at), turn_to(dir, e))

# Where a collector leg ends. At the other collector every way is open; at the
# cell's side both ways along the main road are, and straight on only into a
# collector that lines up.
def cut_exit(inner: Bool, +seed: U32, +ci: U32, +cj: U32, +dir: U32, +t1: U32, +turn: U32) -> Leg & U32:
  match inner:
    case True{}:
      +at = cut_on(seed, ci, cj, U32.is_even(dir))
      +d2 = turn_to(dir, pick_exit(turn, True{}, True{}, True{}))
      (cut_from(seed, ci, cj, d2, Bool.pick(U32, U32.is_eq(d2, dir), t1, at)), 0)
    case False{}:
      +at = cut_on(seed, ci, cj, U32.is_even(dir))
      +so = U32.is_eq(cut_on(seed, next_i(ci, dir), next_j(cj, dir), U32.is_even(dir)), at)
      +e = pick_exit(turn, True{}, so, True{})
      side_exit(U32.is_eq(e, 1), seed, ci, cj, dir, at, e)

# The road the route takes at the end of a leg, for the turn the driver
# chose, and the centimetres into it where the car comes onto it.
def leg_after(l: Leg, +seed: U32, +turn: U32) -> Leg & U32:
  match l:
    case Leg{+i, +j, +dir, length}:
      +ni = next_i(i, dir)
      +nj = next_j(j, dir)
      (leg_from(seed, ni, nj, exit_at(seed, ni, nj, dir, turn)), 0)
    case Cut{+ci, +cj, +dir, +t0, length}:
      +t1 = cut_end(seed, ci, cj, dir, t0)
      cut_exit(Bool.and(U32.is_ne(t1, 0), U32.is_ne(t1, 65536)), seed, ci, cj, dir, t1, turn)

def onward(pair: Leg & U32, +over: U32) -> Leg & U32:
  match pair:
    case (l, s):
      (l, U32.add(s, over))

# Walking the route: `along` is centimetres into the leg. A tick covers under a
# metre and a leg is hundreds, so one crossing is all a tick can pass.
def crossed(over: Bool, +l: Leg, +along: U32, +seed: U32, +turn: U32) -> Leg & U32:
  match over:
    case True{}:
      onward(leg_after(l, seed, turn), U32.sub(along, leg_length(l)))
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

# The lane centre on each class of road. A collector has one lane each way:
# the car keeps half the way to the kerb of its 4.5 m half. A lokal street
# is 4 m wide and shared: the car keeps a metre left of its middle.
def lane_offset_on(code: U32, l: Lane) -> U32:
  match code:
    case 1:
      lane_offset(l)
    case 2:
      225
    case _:
      100

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

# Traffic thickens as the shift goes on: the spread of a fresh car's gap
# shrinks from 50 m to 25 m over the first four minutes.
def respawn_gap(id: U32, +tick: U32) -> U32:
  U32.add(7000, U32.mod(U32.div(mix(id, tick), 3), U32.sub(5000, U32.min(U32.div(tick, 6), 2500))))

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
def scenario_at(p: Player, +cars: List<&2, Car>, zone: M.Zone, hit: Bool, red: Bool) -> R.Scenario:
  match p:
    case Player{+lane, +speed, signal, lamp, moving, target}:
      +changing = Bool.or(signalling(signal), Bool.not(U32.is_eq(moving, 0)))
      # A scenario carries the signs in force at the moment; the game posts no
      # sign duty, so it names the clean act apart from the lane facts.
      R.Scenario{R.Road{zone, R.Left{}, False{}, True{}, red, False{}, False{}, False{}, False{}, False{}, R.NoPriority{}, True{}},
                 R.clean_load(), R.clean_gear(),
                 motion_for(kmh(speed), changing, changing),
                 R.clean_yield(), R.clean_docs(),
                 R.act_in_lane(lane_use(lane), outruns_all(lane, speed, cars), hit)}

def scenario_among(p: Player, +cars: List<&2, Car>, zone: M.Zone, hit: Bool) -> R.Scenario:
  scenario_at(p, cars, zone, hit, False{})

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

# ===========================================================================
# Lokal streets
#
# A tree block's streets are a network of ways (lokal.bend). On a main road
# the doors are the mouths of the blocks either side of it: a tap of the
# indicator up to sixty metres before a door, away from a crossing, turns the
# car in there. On a lokal street a tap chooses the next junction's turn, by
# the same rule as at a crossing; a dead end is a turning circle; at a mouth
# onto a main road the car turns out, left unless it signalled right.
# ===========================================================================

# On the main road, the network of the armed door's block once it is made,
# under the door's key.
type Lok is Data:
  Main{key: U32, net: List<&2, L.Way>}
  Side{net: List<&2, L.Way>, way: U32, fwd: Bool, length: U32}

# Whether the leg's doors are made yet, the doors, the door armed (or none)
# and its side, and whether the car is on the main road or a lokal street.
type Place is Data:
  Place{known: Bool, doors: List<&2, L.Door>, door: U32, left: Bool, lok: Lok}

# Where a tick leaves the car, and whether it passed a crossing or came out
# onto a main road: either way the traffic is the new road's.
type Pos is Data:
  Pos{leg: Leg, along: U32, turn: U32, place: Place, passed: Bool}

def no_door() -> U32:
  4294967295

def fresh_place() -> Place:
  Place{False{}, Nil{}, no_door(), False{}, Main{no_door(), Nil{}}}

def door_reach_cm() -> U32:
  6000

def lok_side(l: Lok) -> Bool:
  match l:
    case Main{key, net}:
      False{}
    case Side{net, way, fwd, length}:
      True{}

def on_side(+p: Place) -> Bool:
  match p:
    case Place{known, doors, door, left, lok}:
      lok_side(lok)

# A lokal street is a residential road: 30 km/h.
def zone_at(side: Bool, +leg: Leg) -> M.Zone:
  match side:
    case True{}:
      M.Residential{}
    case False{}:
      zone_on(leg)

# The mouths of the collectors inside the cells either side of a main road
# are doors too. The collector of cell (ki, kj) starts on the road and runs
# away from it; the other cell's ends on it.
def gate_if(here: Bool, +at: U32, +left: Bool, +ci: U32, +cj: U32, +dir: U32, acc: List<&2, L.Door>) -> List<&2, L.Door>:
  match here:
    case False{}:
      acc
    case True{}:
      L.Gate{at, left, ci, cj, dir} <> acc

def gate_cm(+k: W.Curve, +t: U32, +length: U32, +fwd: Bool) -> U32:
  +a = L.length_to(k, t)
  Bool.pick(U32, fwd, a, U32.sub(length, U32.min(a, length)))

def gates_of(+seed: U32, +ki: U32, +kj: U32, +east: Bool, +length: U32, +fwd: Bool, acc: List<&2, L.Door>) -> List<&2, L.Door>:
  +own = Bool.pick(Bool, east, Bool.not(fwd), fwd)
  +oi = Bool.pick(U32, east, ki, U32.sub(ki, 1))
  +oj = Bool.pick(U32, east, U32.sub(kj, 1), kj)
  +k = W.curve_of(seed, ki, kj, east)
  +bt = cut_on(seed, ki, kj, east)
  +at = cut_on(seed, oi, oj, east)
  gate_if(U32.is_ne(bt, 0), gate_cm(k, bt, length, fwd), own, ki, kj, Bool.pick(U32, east, 2, 1),
    gate_if(U32.is_ne(at, 0), gate_cm(k, at, length, fwd), Bool.not(own), oi, oj, Bool.pick(U32, east, 0, 3), acc))

# A leg's doors are made when a tap first needs them, unless the worker
# brought them first (`with_doors`).
def doors_if(known: Bool, +seed: U32, l: Leg, ds: List<&2, L.Door>) -> List<&2, L.Door>:
  match known:
    case True{}:
      ds
    case False{}:
      match l:
        case Leg{+i, +j, +dir, +length}:
          +ki = key_i(i, dir)
          +kj = key_j(j, dir)
          gates_of(seed, ki, kj, eastward(dir), length, plus(dir),
            L.doors_of(seed, ki, kj, eastward(dir), length, plus(dir)))
        case Cut{+ci, +cj, +dir, +t0, length}:
          +eu = U32.is_even(dir)
          L.cut_doors(seed, ci, cj, eu, cut_on(seed, ci, cj, eu), t0, cut_end(seed, ci, cj, dir, t0),
                      Bool.or(U32.is_eq(dir, 0), U32.is_eq(dir, 1)))

# The nearest door on the chosen side, ahead and within reach.
def door_ahead(ds: List<&2, L.Door>, +left: Bool, +along: U32, +best: U32) -> U32:
  match ds:
    case Nil{}:
      best
    case Con{+d, r}:
      +at = L.door_cm(d)
      +ok = Bool.and(Bool.and(Bool.not(Bool.xor(L.door_left(d), left)), U32.is_lt(along, at)),
            Bool.and(U32.is_le(U32.sub(at, along), door_reach_cm()), U32.is_lt(at, best)))
      door_ahead(r, left, along, Bool.pick(U32, ok, at, best))

def doors_tap(tap: Bool, +seed: U32, l: Leg) -> List<&2, L.Door>:
  match tap:
    case True{}:
      doors_if(False{}, seed, l, Nil{})
    case False{}:
      Nil{}

def doors_when(known: Bool, +tap: Bool, +seed: U32, l: Leg, ds: List<&2, L.Door>) -> List<&2, L.Door>:
  match known:
    case True{}:
      ds
    case False{}:
      doors_tap(tap, seed, l)

def no_door_rec() -> L.Door:
  L.Door{0, False{}, 0, 0, 0, W.Pt{0, 0}}

# The key a block's network is kept under; a gate has no network.
def door_key(d: L.Door) -> U32:
  match d:
    case L.Door{at, dl, ci, cj, blk, p}:
      W.hash4(3, ci, cj, blk, 13)
    case L.Gate{at, dl, ci, cj, dir}:
      no_door()

def net_for(cached: Bool, net: List<&2, L.Way>, +seed: U32, +ci: U32, +cj: U32, +blk: U32) -> List<&2, L.Way>:
  match cached:
    case True{}:
      net
    case False{}:
      L.net_at(seed, ci, cj, blk)

# Turning in at a door: the block's network is made now, and the car starts
# on the way in from the mouth's kerb. At a gate the car starts on the
# collector, at its mouth.
def enter_door(d: L.Door, +seed: U32, +over: U32, +leg: Leg, +key: U32, +made: List<&2, L.Way>) -> Pos:
  match d:
    case L.Door{at, dl, +ci, +cj, +blk, +p}:
      +net = net_for(U32.is_eq(key, W.hash4(3, ci, cj, blk, 13)), made, seed, ci, cj, blk)
      +k = L.way_from(net, p, 0, L.none())
      Pos{leg, over, 1, Place{True{}, Nil{}, no_door(), False{}, Side{net, k, True{}, L.length_at(net, k)}}, False{}}
    case L.Gate{at, dl, +ci, +cj, +dir}:
      Pos{cut_from(seed, ci, cj, dir, Bool.pick(U32, plus(dir), 0, 65536)), over, 1, fresh_place(), True{}}

def walk_main(pair: Leg & U32, +was: U32, +known: Bool, ds: List<&2, L.Door>, +door: U32, +left: Bool, +turn: U32, +key: U32, +net: List<&2, L.Way>) -> Pos:
  match pair:
    case (+leg, +along):
      +passed = U32.is_lt(along, was)
      Pos{leg, along, Bool.pick(U32, passed, 1, turn),
          Bool.pick(Place, passed, fresh_place(), Place{known, ds, door, left, Main{key, net}}), passed}

def main_go(enter: Bool, +leg: Leg, +along: U32, +to: U32, +seed: U32, +turn: U32, +known: Bool, +ds: List<&2, L.Door>, +door: U32, +left: Bool, +key: U32, +net: List<&2, L.Way>) -> Pos:
  match enter:
    case True{}:
      enter_door(L.door_at(ds, door, left, no_door_rec()), seed, U32.sub(to, door), leg, key, net)
    case False{}:
      walk_main(walked(leg, to, seed, turn), along, known, ds, door, left, turn, key, net)

def main_move(+leg: Leg, +along: U32, +dist: U32, +seed: U32, +turn: U32, +known: Bool, +ds: List<&2, L.Door>, +door: U32, +left: Bool, +key: U32, +net: List<&2, L.Way>) -> Pos:
  +to = U32.add(along, dist)
  main_go(Bool.and(U32.is_lt(along, door), U32.is_le(door, to)), leg, along, to, seed, turn, known, ds, door, left, key, net)

# Coming out of a mouth onto a main road. The road's own direction at the
# kerb is a right turn when it turns clockwise from the heading out of the
# block. No signal turns left, the turn across no traffic.
def came_out(pair: Leg & U32, +over: U32) -> Pos:
  match pair:
    case (l, a):
      Pos{l, U32.add(a, over), 1, fresh_place(), True{}}

# Whether the car runs the road the way its parameter grows: when it turns
# right exactly when that way is a right turn from the heading out.
def key_way(+h0: W.Pt, +h1: W.Pt, +arr: U32, +turn: U32) -> Bool:
  +right_key = W.slt(0, W.turn_from(L.heading(h0, h1), arr))
  Bool.not(Bool.xor(U32.is_eq(pick_exit(turn, True{}, False{}, True{}), 2), right_key))

def turn_out(k: L.Kerb, +arr: U32, +over: U32, +seed: U32, +turn: U32, +leg: Leg) -> Pos:
  match k:
    case L.Inside{}:
      Pos{leg, over, 1, fresh_place(), True{}}
    case L.Kerb{+ki, +kj, +east, +t, +at}:
      +c = W.curve_of(seed, ki, kj, east)
      +key = key_way(W.curve_at(c, U32.sub(t, U32.min(t, 512))), W.curve_at(c, U32.min(U32.add(t, 512), 65536)), arr, turn)
      came_out(road_at(seed, ki, kj, east, at, Bool.pick(U32, east, Bool.pick(U32, key, 1, 3), Bool.pick(U32, key, 2, 0))), over)
    case L.OnCut{+ci, +cj, +u, +t}:
      +f = W.frame_of(seed, ci, cj)
      +x = cut_on(seed, ci, cj, u)
      +ta = U32.sub(t, U32.min(t, 512))
      +tb = U32.min(U32.add(t, 512), 65536)
      +key = key_way(W.frame_at(f, Bool.pick(U32, u, x, ta), Bool.pick(U32, u, ta, x)),
                     W.frame_at(f, Bool.pick(U32, u, x, tb), Bool.pick(U32, u, tb, x)), arr, turn)
      came_out(cut_through(seed, ci, cj, Bool.pick(U32, u, Bool.pick(U32, key, 2, 0), Bool.pick(U32, key, 1, 3)), t), over)

# At a junction: the turn chosen if its way is there, else straight on, left,
# right, and back round the turning circle only at a dead end.
def onto(c: L.Choice, +net: List<&2, L.Way>, +way: U32, +fwd: Bool, +over: U32, +turn: U32, +leg: Leg) -> Pos:
  match c:
    case L.Choice{+lo, +li, +lf, +so, +si, +sf, +ro, +ri, +rf}:
      +e = pick_exit(turn, lo, so, ro)
      +k = Bool.pick(U32, U32.is_eq(e, 0), li, Bool.pick(U32, U32.is_eq(e, 1), si, Bool.pick(U32, U32.is_eq(e, 2), ri, way)))
      +f = Bool.pick(Bool, U32.is_eq(e, 0), lf, Bool.pick(Bool, U32.is_eq(e, 1), sf, Bool.pick(Bool, U32.is_eq(e, 2), rf, Bool.not(fwd))))
      Pos{leg, over, 1, Place{True{}, Nil{}, no_door(), False{}, Side{net, k, f, L.length_at(net, k)}}, False{}}

def out_or_on(out: Bool, +kerb: L.Kerb, +arr: U32, +c: L.Choice, +net: List<&2, L.Way>, +way: U32, +fwd: Bool, +over: U32, +seed: U32, +turn: U32, +leg: Leg) -> Pos:
  match out:
    case True{}:
      turn_out(kerb, arr, over, seed, turn, leg)
    case False{}:
      onto(c, net, way, fwd, over, turn, leg)

def from_arrival(x: L.Arrival, +net: List<&2, L.Way>, +way: U32, +fwd: Bool, +over: U32, +seed: U32, +turn: U32, +leg: Leg) -> Pos:
  match x:
    case L.Arrival{+out, +arr, +c}:
      out_or_on(L.is_kerb(out), out, arr, c, net, way, fwd, over, seed, turn, leg)

def side_go(over: Bool, +net: List<&2, L.Way>, +way: U32, +fwd: Bool, +length: U32, +to: U32, +seed: U32, +turn: U32, +leg: Leg) -> Pos:
  match over:
    case False{}:
      Pos{leg, to, turn, Place{True{}, Nil{}, no_door(), False{}, Side{net, way, fwd, length}}, False{}}
    case True{}:
      from_arrival(L.arrive(net, way, fwd), net, way, fwd, U32.sub(to, length), seed, turn, leg)

def side_move(+net: List<&2, L.Way>, +way: U32, +fwd: Bool, +length: U32, +along: U32, +dist: U32, +seed: U32, +turn: U32, +leg: Leg) -> Pos:
  +to = U32.add(along, dist)
  side_go(U32.is_le(length, to), net, way, fwd, length, to, seed, turn, leg)

# One tick's move. On the main road a tap near a crossing chooses the turn
# there and one away from it arms the nearest door on its side, if any; on a
# lokal street a tap chooses the next junction's turn.
def move_lok(l: Lok, +known: Bool, +doors: List<&2, L.Door>, +door: U32, +left: Bool, +leg: Leg, +along: U32,
             +dist: U32, +seed: U32, +turn: U32, +tl: Bool, +tr: Bool) -> Pos:
  match l:
    case Main{+key, +net}:
      +near = near_crossing(leg, along)
      +tap = Bool.and(Bool.or(tl, tr), Bool.not(near))
      +ds = doors_when(known, tap, seed, leg, doors)
      +found = door_ahead(ds, tl, along, no_door())
      +arm = Bool.and(tap, U32.is_ne(found, no_door()))
      main_move(leg, along, dist, seed, turn_by(near, tl, tr, turn), Bool.or(known, tap), ds,
                Bool.pick(U32, arm, found, door), Bool.pick(Bool, arm, tl, left), key, net)
    case Side{+net, +way, +fwd, +length}:
      side_move(net, way, fwd, length, along, dist, seed,
                Bool.pick(U32, tl, 0, Bool.pick(U32, tr, 2, turn)), leg)

def move(p: Place, +leg: Leg, +along: U32, +dist: U32, +seed: U32, +turn: U32, +tl: Bool, +tr: Bool) -> Pos:
  match p:
    case Place{+known, +doors, +door, +left, lok}:
      move_lok(lok, known, doors, door, left, leg, along, dist, seed, turn, tl, tr)


# ===========================================================================
# Lights
#
# A crossing where an arterial runs has lights. Each approach shows green,
# then amber, then red, in a 24 s cycle; the two axes take turns, with a
# second of red both ways between them, and each crossing starts its cycle
# at its own offset. A car that passes the crossing while its approach shows
# red runs the light: Pasal 106 ayat (4) huruf c.
# ===========================================================================

def cycle_ticks() -> U32:
  1440

def green_ticks() -> U32:
  480

def amber_ticks() -> U32:
  180

def has_lights(+i: U32, +j: U32) -> Bool:
  Bool.or(U32.is_eq(W.smod3(i), 0), U32.is_eq(W.smod3(j), 0))

# Where the approach is in its cycle: 0 green, 1 amber, 2 red.
def light_of(+mine: U32) -> U32:
  Bool.pick(U32, U32.is_lt(mine, green_ticks()), 0,
  Bool.pick(U32, U32.is_lt(mine, U32.add(green_ticks(), amber_ticks())), 1, 2))

# The light for a car heading dir into crossing (i, j) at a tick: 0 green,
# 1 amber, 2 red, 3 no lights.
def light_at(+seed: U32, +i: U32, +j: U32, +dir: U32, +tick: U32) -> U32:
  +t = U32.mod(U32.add(tick, U32.mod(W.hash3(seed, 79, i, j), cycle_ticks())), cycle_ticks())
  +mine = Bool.pick(U32, eastward(dir), t, U32.mod(U32.add(t, U32.div(cycle_ticks(), 2)), cycle_ticks()))
  Bool.pick(U32, has_lights(i, j), light_of(mine), 3)

# The light ahead of a car on a main road; a collector meets no lights.
def light_ahead(+l: Leg, +side: Bool, +seed: U32, +tick: U32) -> U32:
  match l:
    case Leg{+i, +j, +dir, length}:
      Bool.pick(U32, side, 3, light_at(seed, next_i(i, dir), next_j(j, dir), dir, tick))
    case Cut{ci, cj, dir, t0, length}:
      3

# ===========================================================================
# The world
# ===========================================================================

type World is Data:
  World{tick: U32, player: Player, traffic: List<&2, Car>, oncoming: List<&2, Car>,
        distance: U32, zone: M.Zone, charges: List<&2, U32>, status: Status,
        held: Controls, residual: U32, leg: Leg, along: U32, turn: U32,
        place: Place, seed: U32}

def is_crashed(s: Status) -> Bool:
  match s:
    case Driving{}:
      False{}
    case Crashed{}:
      True{}

def player_of(w: World) -> Player:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
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
        fresh_place(), start_seed()}

def drift_if(go: Bool, cars: List<&2, Car>, +dist: U32, +tick: U32) -> List<&2, Car>:
  match go:
    case True{}:
      drift(cars, dist, tick)
    case False{}:
      cars

def drift_oncoming_if(go: Bool, cars: List<&2, Car>, +dist: U32, +tick: U32) -> List<&2, Car>:
  match go:
    case True{}:
      drift_oncoming(cars, dist, tick)
    case False{}:
      cars

# The car has moved to `pos`. The zone is the class of the road it is on, so
# the ceiling changes where the road does. Past a crossing, or out of a lokal
# street, the traffic is the new road's. On a one-lane road every car keeps to
# the kerb lane; on a lokal street the main road's traffic waits, unseen.
def settle(pos: Pos, +tick: U32, player: Player, traffic: List<&2, Car>,
           oncoming: List<&2, Car>, +dist: U32, distance: U32, +input: Controls,
           residual: U32, seed: U32, red: Bool) -> World:
  match pos:
    case Pos{+leg, along, turn, +place, +passed}:
      +side = on_side(place)
      +wide = Bool.and(wide_on(leg), Bool.not(side))
      +zone = zone_at(side, leg)
      +kept = keep_lane(wide, player)
      +traffic2 = keep_left(wide, refresh(passed, drift_if(Bool.not(side), traffic, dist, tick), tick))
      +oncoming2 = keep_left(wide, refresh(passed, drift_oncoming_if(Bool.not(side), oncoming, dist, tick), tick))
      +met = Bool.pick(List<&2, Car>, side, Nil{}, traffic2)
      +hit = blocked(met, lane_of(kept))
      World{tick, kept, traffic2, oncoming2, U32.add(distance, dist), zone,
            spread(R.charges(scenario_at(kept, met, zone, hit, Bool.and(passed, red)))), status_after(hit),
            input, residual, leg, along, turn, place, seed}

def step(frozen: Bool, +tick: U32, player: Player, traffic: List<&2, Car>,
         oncoming: List<&2, Car>, distance: U32, zone: M.Zone,
         charges: List<&2, U32>, +held: Controls, residual: U32,
         +leg: Leg, +along: U32, turn: U32, +place: Place, +seed: U32, +input: Controls) -> World:
  match frozen:
    case True{}:
      World{tick, player, traffic, oncoming, distance, zone, charges, Crashed{},
            held, residual, leg, along, turn, place, seed}
    case False{}:
      +player2 = player_next(player, held, input, Bool.and(wide_on(leg), Bool.not(on_side(place))))
      +dist = roll(speed_of(player2))
      settle(move(place, leg, along, dist, seed, turn, pressed(held_left(input), held_left(held)),
                  pressed(held_right(input), held_right(held))),
             U32.add(tick, 1), player2, traffic, oncoming, dist, distance, input, residual, seed,
             U32.is_eq(light_ahead(leg, on_side(place), seed, tick), 2))

def tick(w: World, input: Controls) -> World:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      step(is_crashed(status), tick, player, traffic, oncoming, distance, zone,
           charges, held, residual, leg, along, turn, place, seed, input)

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
               held, residual, leg, along, turn, place, seed}:
      +total = U32.add(residual, U32.min(ms, 250))
      +count = U32.min(U32.div(U32.mul(total, 60), 1000), 5)
      +left = U32.sub(total, U32.div(U32.mul(count, 1000), 60))
      +spent = run(U32.to_nat(count), World{tick, player, traffic, oncoming, distance,
                                        zone, charges, status, held, left, leg,
                                        along, turn, place, seed}, input)
      spent

def restart(w: World) -> World:
  start()

# ===========================================================================
# What the screen reads
# ===========================================================================

def place_of(w: World) -> Place:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      place

def leg_of(w: World) -> Leg:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      leg

# The class of road the car is on: 1 arterial, 2 collector, 3 lokal street.
def road_code_of(+w: World) -> U32:
  Bool.pick(U32, on_side(place_of(w)), 3, W.class_code(class_on(leg_of(w))))

def speed_kmh(w: World) -> U32:
  kmh(speed_of(player_of(w)))

def zone_of(w: World) -> M.Zone:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      zone

def limit_kmh(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      kmh(limit_of(zone))

def metres(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      U32.div(distance, 100)

def crashed(w: World) -> Bool:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      is_crashed(status)

# The lamp shows the turn chosen at the crossing ahead, or else the lane change.
def turn_signal(+turn: U32, s: Signal) -> Signal:
  Bool.pick(Signal, U32.is_eq(turn, 0), ToLeft{}, Bool.pick(Signal, U32.is_eq(turn, 2), ToRight{}, s))

def turn_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      turn

# An armed door lights the lamp on its side until the car turns in.
def door_signal(+p: Place, s: Signal) -> Signal:
  match p:
    case Place{known, doors, +door, +left, lok}:
      Bool.pick(Signal, U32.is_eq(door, no_door()), s, Bool.pick(Signal, left, ToLeft{}, ToRight{}))

def signal_state(+w: World) -> Signal:
  turn_signal(turn_of(w), door_signal(place_of(w), signal_of(player_of(w))))

def lane_move(w: World) -> U32:
  moving_of(player_of(w))

def lane_target(w: World) -> Lane:
  target_of(player_of(w))

def lane_centre(+w: World) -> U32:
  lane_offset_on(road_code_of(w), lane_of(player_of(w)))

def traffic_of(w: World) -> List<&2, Car>:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      traffic

def along_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      along

def seed_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
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

# ===========================================================================
# The road ahead, for the renderer
#
# The stretch the car is on and the one it takes next, each as points on the
# ground in driving order, its length, and the part of it driven: from `from`
# to `to` centimetres. A main road joined from a lokal street is driven from
# the mouth on; a leg with a door armed, up to the door.
# ===========================================================================

type Piece is Data:
  Piece{id: U32, pts: List<&2, W.Pt>, length: U32, from: U32, to: U32}

def cut_pts(fuel: Nat, +f: W.Frame, +eu: Bool, +at: U32, +t0: U32, +t1: U32, +k: U32, acc: List<&2, W.Pt>) -> List<&2, W.Pt>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +t = W.lerp(t0, t1, U32.mul(k, 2048))
      cut_pts(p, f, eu, at, t0, t1, U32.sub(k, 1), W.frame_at(f, Bool.pick(U32, eu, at, t), Bool.pick(U32, eu, t, at)) <> acc)

def leg_pts(+seed: U32, l: Leg) -> List<&2, W.Pt>:
  match l:
    case Leg{+i, +j, +dir, length}:
      +ps = W.road_pts(seed, key_i(i, dir), key_j(j, dir), eastward(dir))
      Bool.pick(List<&2, W.Pt>, Bool.or(U32.is_eq(dir, 0), U32.is_eq(dir, 3)), List.reverse(&2, W.Pt, ps), ps)
    case Cut{+ci, +cj, +dir, +t0, length}:
      +eu = U32.is_even(dir)
      cut_pts(33n, W.frame_of(seed, ci, cj), eu, cut_on(seed, ci, cj, eu), t0, cut_end(seed, ci, cj, dir, t0), 32, Nil{})

def leg_id(l: Leg) -> U32:
  match l:
    case Leg{i, j, dir, length}:
      W.hash4(1, i, j, dir, 7)
    case Cut{ci, cj, dir, t0, length}:
      W.hash5(5, ci, cj, dir, t0, 11)

def leg_piece(+seed: U32, +l: Leg, +from: U32, +to: U32) -> Piece:
  Piece{leg_id(l), leg_pts(seed, l), leg_length(l), from, to}

def way_piece(w: L.Way, +fwd: Bool) -> Piece:
  match w:
    case L.Way{+a, +b, +pts, +length, ha, hb, kerb}:
      Piece{W.hash6(2, W.pt_x(a), W.pt_z(a), W.pt_x(b), W.pt_z(b), Bool.to_u32(fwd), 0),
            Bool.pick(List<&2, W.Pt>, fwd, pts, List.reverse(&2, W.Pt, pts)), length, 0, length}

def lok_piece(l: Lok, +seed: U32, +leg: Leg, +from: U32, +to: U32) -> Piece:
  match l:
    case Main{key, net}:
      leg_piece(seed, leg, from, to)
    case Side{net, +way, +fwd, length}:
      way_piece(L.nth_way(net, way), fwd)

def pos_piece(x: Pos, +seed: U32) -> Piece:
  match x:
    case Pos{+leg, +along, turn, place, passed}:
      match place:
        case Place{known, doors, door, left, lok}:
          lok_piece(lok, seed, leg, along, leg_length(leg))

def next_piece(pair: Leg & U32, +seed: U32) -> Piece:
  match pair:
    case (+l, +s):
      leg_piece(seed, l, s, leg_length(l))

# A door whose network is not made yet plans no piece past it: the plan
# changes when the network comes, and the car makes it itself if it gets
# to the door first.
def door_ready(+d: L.Door, +key: U32) -> Bool:
  match d:
    case L.Door{at, dl, ci, cj, blk, p}:
      U32.is_eq(key, door_key(d))
    case L.Gate{at, dl, ci, cj, dir}:
      True{}

def past_door(ready: Bool, +d: L.Door, +seed: U32, +leg: Leg, +key: U32, +net: List<&2, L.Way>) -> List<&2, Piece>:
  match ready:
    case True{}:
      [pos_piece(enter_door(d, seed, 0, leg, key, net), seed)]
    case False{}:
      Nil{}

def next_main(armed: Bool, +p: Place, +seed: U32, +leg: Leg, +turn: U32, +key: U32, +net: List<&2, L.Way>) -> List<&2, Piece>:
  match armed:
    case True{}:
      match p:
        case Place{known, +doors, +door, +left, lok}:
          +d = L.door_at(doors, door, left, no_door_rec())
          past_door(door_ready(d, key), d, seed, leg, key, net)
    case False{}:
      [next_piece(leg_after(leg, seed, turn), seed)]

def ahead_of(l: Lok, +p: Place, +seed: U32, +leg: Leg, +along: U32, +turn: U32) -> List<&2, Piece>:
  match l:
    case Main{+key, +net}:
      match p:
        case Place{known, doors, +door, left, lok}:
          +armed = U32.is_ne(door, no_door())
          leg_piece(seed, leg, 0, Bool.pick(U32, armed, door, leg_length(leg))) <>
            next_main(armed, p, seed, leg, turn, key, net)
    case Side{+net, +way, +fwd, +length}:
      [way_piece(L.nth_way(net, way), fwd),
       pos_piece(from_arrival(L.arrive(net, way, fwd), net, way, fwd, 0, seed, turn, leg), seed)]

def plan(w: World) -> List<&2, Piece>:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, +leg, +along, +turn, +place, +seed}:
      match place:
        case Place{known, doors, door, left, lok}:
          ahead_of(lok, place, seed, leg, along, turn)

def lok_key(l: Lok) -> U32:
  match l:
    case Main{key, net}:
      key
    case Side{net, way, fwd, length}:
      W.hash2(U32.add(way, 1), Bool.to_u32(fwd), 3)

# Changes whenever the plan does, so the renderer asks for it only then.
def plan_key(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      match place:
        case Place{known, doors, door, left, lok}:
          W.hash5(leg_id(leg), turn, door, Bool.to_u32(left), lok_key(lok), 9)

# ===========================================================================
# Made ahead
#
# A leg's doors and a block's network take milliseconds to make. A worker
# makes them ahead with the functions below, the ones the model itself
# calls, and the model takes each only where it is the value it would make:
# the doors of the leg the car is on, not yet made; the network of the door
# armed. Without them the model makes its own, as before.
# ===========================================================================

def leg_doors(+seed: U32, l: Leg) -> List<&2, L.Door>:
  doors_if(False{}, seed, l, Nil{})

def door_net(+seed: U32, d: L.Door) -> List<&2, L.Way>:
  match d:
    case L.Door{at, dl, +ci, +cj, +blk, p}:
      L.net_at(seed, ci, cj, blk)
    case L.Gate{at, dl, ci, cj, dir}:
      Nil{}

def first_of(pair: Leg & U32) -> Leg:
  match pair:
    case (l, s):
      l

# The leg the car is on and the legs each turn would take it onto next.
def legs_ahead(w: World) -> List<&2, Leg>:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, +leg, along, turn, place, +seed}:
      [leg, first_of(leg_after(leg, seed, 0)), first_of(leg_after(leg, seed, 1)), first_of(leg_after(leg, seed, 2))]

def leg_key(w: World) -> U32:
  leg_id(leg_of(w))

def place_known(p: Place) -> Bool:
  match p:
    case Place{known, doors, door, left, lok}:
      known

def needs_doors(w: World) -> Bool:
  Bool.not(place_known(place_of(w)))

def with_doors(w: World, l: Leg, ds: List<&2, L.Door>) -> World:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, +leg, along, turn, place, seed}:
      match place:
        case Place{+known, doors, door, left, lok}:
          +fits = Bool.and(Bool.not(known), U32.is_eq(leg_id(l), leg_id(leg)))
          World{tick, player, traffic, oncoming, distance, zone, charges, status,
                held, residual, leg, along, turn,
                Place{Bool.or(known, fits), Bool.pick(List<&2, L.Door>, fits, ds, doors), door, left, lok}, seed}

# The door armed, or a gate when none is.
def armed_in(p: Place) -> L.Door:
  match p:
    case Place{known, +doors, +door, +left, lok}:
      Bool.pick(L.Door, U32.is_eq(door, no_door()), L.Gate{0, False{}, 0, 0, 0},
                L.door_at(doors, door, left, no_door_rec()))

def armed(w: World) -> L.Door:
  armed_in(place_of(w))

def lok_wants(l: Lok, +want: U32) -> Bool:
  match l:
    case Main{key, net}:
      Bool.and(U32.is_ne(want, no_door()), U32.is_ne(key, want))
    case Side{net, way, fwd, length}:
      False{}

# Whether the armed door's network is still to make.
def place_wants(+p: Place) -> Bool:
  match p:
    case Place{known, doors, door, left, lok}:
      lok_wants(lok, door_key(armed_in(p)))

def wants_net(w: World) -> Bool:
  place_wants(place_of(w))

def lok_with(l: Lok, +want: U32, net: List<&2, L.Way>) -> Lok:
  match l:
    case Main{+key, n0}:
      +fits = Bool.and(U32.is_ne(want, no_door()), U32.is_ne(key, want))
      Main{Bool.pick(U32, fits, want, key), Bool.pick(List<&2, L.Way>, fits, net, n0)}
    case Side{net0, way, fwd, length}:
      Side{net0, way, fwd, length}

def with_net(w: World, d: L.Door, net: List<&2, L.Way>) -> World:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      match place:
        case Place{known, +doors, +door, +left, lok}:
          +want = door_key(L.door_at(doors, door, left, no_door_rec()))
          +given = door_key(d)
          World{tick, player, traffic, oncoming, distance, zone, charges, status,
                held, residual, leg, along, turn,
                Place{known, doors, door, left, lok_with(lok, Bool.pick(U32, U32.is_eq(want, given), want, no_door()), net)}, seed}

# ===========================================================================
# The shift
#
# A drive is a shift: three minutes of fares. An order is a passenger waiting
# halfway along a road; the car stops there to take them aboard, then carries
# them to another road before the time the order gives. A charge is a ticket
# when it starts and again every five seconds while it lasts, each with the
# points Perpol 5/2021 Pasal 35 and 36 put on the licence. The shift ends when
# the clock runs out, the car crashes or the points reach the 12 at which
# Pasal 38 holds the licence.
# ===========================================================================

type Phase is Data:
  Running{}
  Over{}
  Held{}
  Wrecked{}

type Ticket is Data:
  Ticket{id: U32, tick: U32, points: U32}

# Where the passenger waits (`aboard` False) or goes (True): a stop on the
# road named by its west or north crossing (ki, kj) and its axis. `fare` and
# `due` are set when the passenger boards.
type Order is Data:
  Order{aboard: Bool, ki: U32, kj: U32, east: Bool, t: U32, cm: U32, fare: U32, due: U32}

type Shift is Data:
  Shift{drive: World, points: U32, tickets: List<&2, Ticket>, live: List<&2, Ticket>,
        phase: Phase, order: Order, earned: U32, served: U32, stars: U32}

# A charge that lasts is ticketed again after this many ticks.
def again_ticks() -> U32:
  300

# Four minutes.
def shift_ticks() -> U32:
  14400

# ---- Orders ---------------------------------------------------------------

# Where a stop is on a road: its parameter along the road's curve and the
# centimetres from the road's west or north crossing to it.
def stop_on(+seed: U32, +aboard: Bool, +ki: U32, +kj: U32, +east: Bool, +t: U32) -> Order:
  Order{aboard, ki, kj, east, t, L.length_to(W.curve_of(seed, ki, kj, east), t), 0, 0}

# A stop on a road off the crossing (i, j) the car drives toward heading
# `dir`: the road a turn there takes, or half the time the road one more
# turn on, somewhere in its middle three fifths. `exit_at` takes only roads
# that are there, so every stop is on a road the car can reach.
def stop_past(+seed: U32, +i: U32, +j: U32, +dir: U32, +n: U32, +aboard: Bool) -> Order:
  +h = W.hash4(seed, 71, i, j, n)
  +d1 = exit_at(seed, i, j, dir, U32.mod(h, 3))
  +i2 = next_i(i, d1)
  +j2 = next_j(j, d1)
  +d2 = exit_at(seed, i2, j2, d1, U32.mod(U32.shrn(h, 4n), 3))
  +far = U32.is_eq(U32.and(U32.shrn(h, 8n), 1), 1)
  +ii = Bool.pick(U32, far, i2, i)
  +jj = Bool.pick(U32, far, j2, j)
  +dd = Bool.pick(U32, far, d2, d1)
  stop_on(seed, aboard, key_i(ii, dd), key_j(jj, dd), eastward(dd), U32.add(13000, U32.mod(U32.shrn(h, 12n), 26000)))

# The crossing the car drives toward, or the corner of the cell it is in.
def toward_i(l: Leg) -> U32:
  match l:
    case Leg{+i, j, +dir, length}:
      next_i(i, dir)
    case Cut{ci, cj, dir, t0, length}:
      ci

def toward_j(l: Leg) -> U32:
  match l:
    case Leg{i, +j, +dir, length}:
      next_j(j, dir)
    case Cut{ci, cj, dir, t0, length}:
      cj

# Centimetres from the road's west or north crossing to the car.
def from_key(+dir: U32, +along: U32, +length: U32) -> U32:
  Bool.pick(U32, Bool.or(U32.is_eq(dir, 1), U32.is_eq(dir, 2)), along, U32.sub(length, along))

# A parameter on the road the car is on, some way ahead of it, as a fraction
# of the road in 65536ths; or 0 when too little of the road is left.
def ahead_t(+dir: U32, +along: U32, +length: U32, +h: U32) -> U32:
  +left = U32.sub(length, along)
  +room = U32.is_lt(32000, left)
  +gap = U32.add(15000, U32.mod(h, U32.sub(Bool.pick(U32, room, left, 32000), 30000)))
  +at = Bool.pick(U32, Bool.or(U32.is_eq(dir, 1), U32.is_eq(dir, 2)), U32.add(along, gap), U32.sub(U32.sub(length, along), gap))
  Bool.pick(U32, room, U32.div(U32.mul(U32.shrn(at, 4n), 65536), U32.shrn(length, 4n)), 0)

def leg_dir(l: Leg) -> U32:
  match l:
    case Leg{i, j, dir, length}:
      dir
    case Cut{ci, cj, dir, t0, length}:
      dir

# A stop past the crossing the car drives toward.
def stop_beyond(+seed: U32, +l: Leg, +n: U32, +aboard: Bool) -> Order:
  stop_past(seed, toward_i(l), toward_j(l), leg_dir(l), n, aboard)

def pickup_on(+t: U32, +seed: U32, +l: Leg, +n: U32) -> Order:
  match l:
    case Leg{+i, +j, +dir, length}:
      Bool.pick(Order, U32.is_eq(t, 0), stop_beyond(seed, l, n, False{}),
                stop_on(seed, False{}, key_i(i, dir), key_j(j, dir), eastward(dir), t))
    case Cut{ci, cj, dir, t0, length}:
      stop_beyond(seed, l, n, False{})

# The next passenger waits further along the road the car is on when enough
# of it is left, else on a road by the crossing ahead.
def pickup_near(+seed: U32, +l: Leg, +along: U32, +n: U32) -> Order:
  match l:
    case Leg{+i, +j, +dir, +length}:
      pickup_on(ahead_t(dir, along, length, W.hash3(seed, 73, n, along)), seed, l, n)
    case Cut{ci, cj, dir, t0, length}:
      pickup_on(0, seed, l, n)

# A fare: a flag fall of Rp5.000 and Rp5 a metre as the crow flies, rounded
# down to Rp500.
def fare_for(+cm: U32) -> U32:
  +rp = U32.add(5000, U32.mul(U32.div(cm, 100), 5))
  U32.sub(rp, U32.mod(rp, 500))

# The time an order allows: a second for every six metres as the crow flies,
# and fifteen seconds to stop and set down. Each passenger served, up to
# five, asks for 0.6 m a second more: 9 m a second by the sixth order.
def allow_for(+cm: U32, +served: U32) -> U32:
  U32.add(900, U32.div(U32.mul(cm, 60), U32.add(600, U32.mul(60, U32.min(served, 5)))))

def stop_point(+seed: U32, o: Order) -> W.Pt:
  match o:
    case Order{aboard, ki, kj, east, t, cm, fare, due}:
      W.curve_point(seed, ki, kj, east, t)

def priced(o: Order, +seed: U32, +from: W.Pt, +now: U32, +served: U32) -> Order:
  match o:
    case Order{aboard, +ki, +kj, +east, +t, cm, fare, due}:
      +d = W.dist(from, W.curve_point(seed, ki, kj, east, t))
      Order{True{}, ki, kj, east, t, cm, fare_for(d), U32.add(now, allow_for(d, served))}

# The passenger boards: the drop-off is past the crossing ahead.
def boarded(+seed: U32, +o: Order, +leg: Leg, +n: U32, +now: U32) -> Order:
  priced(stop_beyond(seed, leg, n, True{}), seed, stop_point(seed, o), now, n)

# The car is at the stop when it stands still on that road, either way,
# within 25 metres of it, out of any lokal street.
def at_order(+o: Order, +l: Leg, +along: U32, +speed: U32, +side: Bool) -> Bool:
  match o:
    case Order{aboard, +ki, +kj, +east, t, +cm, fare, due}:
      match l:
        case Leg{+i, +j, +dir, +length}:
          +pos = from_key(dir, along, length)
          Bool.and(U32.is_eq(speed, 0),
          Bool.and(Bool.not(side),
          Bool.and(U32.is_eq(key_i(i, dir), ki),
          Bool.and(U32.is_eq(key_j(j, dir), kj),
          Bool.and(Bool.not(Bool.xor(eastward(dir), east)),
                   U32.is_lt(U32.sub(U32.max(pos, cm), U32.min(pos, cm)), 2500))))))
        case Cut{ci, cj, dir, t0, length}:
          False{}

# Set down on time, the fare is paid in full; late, half of it.
def paid(+fare: U32, +due: U32, +now: U32) -> U32:
  Bool.pick(U32, U32.is_lt(due, now), U32.div(fare, 2), fare)

# ---- The shift -------------------------------------------------------------

# A shift starts in the kerb lane, the lane Pasal 108 ayat (1) gives a driver.
def kerb_side(p: Player) -> Player:
  match p:
    case Player{lane, speed, signal, lamp, moving, target}:
      Player{Outer{}, speed, signal, lamp, moving, Outer{}}

# The car that starts every shift, on an arterial no seed can drop: crossing
# (1, 3) is odd in i, and only a crossing even in both drops a road. The
# traffic ahead starts at least seventy metres off, as past a crossing.
def reseed(w: World, +seed: U32) -> World:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, s0}:
      +first = leg_from(seed, 1, 3, 1)
      World{tick, kerb_side(player), refresh(True{}, traffic, 0), oncoming, distance, zone_on(first), charges, status,
            held, residual, first, along, turn, place, seed}

def start_on(+seed: U32) -> World:
  reseed(start(), seed)

def shift_start(+seed: U32) -> Shift:
  Shift{start_on(seed), 0, Nil{}, Nil{}, Running{}, pickup_near(seed, leg_from(seed, 1, 3, 1), 20000, 0), 0, 0, 50}

def tick_of(w: World) -> U32:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      tick

def charges_of(w: World) -> List<&2, U32>:
  match w:
    case World{tick, player, traffic, oncoming, distance, zone, charges, status,
               held, residual, leg, along, turn, place, seed}:
      charges

# The tick a charge was last ticketed, or none when it was not live.
def last_ticket(live: List<&2, Ticket>, +id: U32, +none: U32) -> U32:
  match live:
    case Nil{}:
      none
    case h <> t:
      match h:
        case Ticket{+tid, tick, points}:
          Bool.pick(U32, U32.is_eq(tid, id), tick, last_ticket(t, id, none))

# The tick of a charge that was not live.
def not_live() -> U32:
  U32.sub(0, 1)

# A charge is ticketed now unless it was live and ticketed less than
# `again_ticks` ago. A charge that puts no points on the licence is a warning,
# given once while it lasts.
def ticket_tick(+last: U32, +now: U32, +points: U32) -> U32:
  +fresh = U32.is_eq(last, not_live())
  +again = Bool.and(U32.is_ne(points, 0), Bool.not(U32.is_lt(U32.sub(now, last), again_ticks())))
  Bool.pick(U32, Bool.or(fresh, again), now, last)

# The charges live now, each with the tick it was last ticketed.
def judge(ids: List<&2, U32>, +live: List<&2, Ticket>, +now: U32) -> List<&2, Ticket>:
  match ids:
    case Nil{}:
      Nil{}
    case +id <> t:
      Ticket{id, ticket_tick(last_ticket(live, id, not_live()), now, R.points_of(id)), R.points_of(id)}
        <> judge(t, live, now)

# The tickets written now: the live charges ticketed this tick.
def written(live: List<&2, Ticket>, +now: U32) -> List<&2, Ticket>:
  match live:
    case Nil{}:
      Nil{}
    case +h <> +t:
      match h:
        case Ticket{id, +tick, points}:
          Bool.pick(List<&2, Ticket>, U32.is_eq(tick, now), h <> written(t, now), written(t, now))

def points_in(ts: List<&2, Ticket>) -> U32:
  match ts:
    case Nil{}:
      0
    case h <> t:
      match h:
        case Ticket{id, tick, points}:
          U32.add(points, points_in(t))

def append(a: List<&2, Ticket>, b: List<&2, Ticket>) -> List<&2, Ticket>:
  match a:
    case Nil{}:
      b
    case h <> t:
      h <> append(t, b)

# A crash ends the shift first, then a held licence, then the clock.
def phase_after(crash: Bool, +points: U32, +now: U32) -> Phase:
  Bool.pick(Phase, crash, Wrecked{},
  Bool.pick(Phase, Bool.not(U32.is_lt(points, Lic.held_at_points())), Held{},
  Bool.pick(Phase, U32.is_lt(now, shift_ticks()), Running{}, Over{})))

def is_running(p: Phase) -> Bool:
  match p:
    case Running{}:
      True{}
    case _:
      False{}

def speed_now(w: World) -> U32:
  speed_of(player_of(w))

def side_now(w: World) -> Bool:
  on_side(place_of(w))

# At the order's road: a waiting passenger boards and the next order is the
# drop-off; a passenger aboard is set down, paid, and the next order is a
# pickup from there.
def served_on(arrived: Bool, +seed: U32, +o: Order, +leg: Leg, +along: U32, +now: U32, +served: U32) -> Order & U32:
  match arrived:
    case False{}:
      (o, 0)
    case True{}:
      match o:
        case Order{aboard, ki, kj, east, t, cm, +fare, +due}:
          match aboard:
            case False{}:
              (boarded(seed, o, leg, served, now), 0)
            case True{}:
              (pickup_near(seed, leg, along, U32.add(served, 1)), paid(fare, due, now))

def order_was_aboard(o: Order) -> Bool:
  match o:
    case Order{aboard, ki, kj, east, t, cm, fare, due}:
      aboard

# ---- The rating -------------------------------------------------------------
#
# The passengers rate the driver in tenths of a star, from 1.0 to 5.0, and a
# fare is paid in proportion: Rp10.000 at five stars is Rp8.000 at four. A
# shift starts at five. Every point a ticket puts on the licence costs a
# tenth; a drop-off on time earns two tenths back, a late one costs five.

def stars_lost(+stars: U32, +lost: U32) -> U32:
  Bool.pick(U32, U32.is_lt(U32.add(lost, 10), stars), U32.sub(stars, lost), 10)

def stars_after(+stars: U32, done: Bool, +late: Bool) -> U32:
  match done:
    case False{}:
      stars
    case True{}:
      Bool.pick(U32, late, stars_lost(stars, 5), U32.min(U32.add(stars, 2), 50))

def rated(+pay: U32, +stars: U32) -> U32:
  +x = U32.div(U32.mul(pay, stars), 50)
  U32.sub(x, U32.mod(x, 100))

def order_due(o: Order) -> U32:
  match o:
    case Order{aboard, ki, kj, east, t, cm, fare, due}:
      due

def stars_of(s: Shift) -> U32:
  match s:
    case Shift{drive, points, tickets, live, phase, order, earned, served, stars}:
      stars

def paid_up(next: Order & U32, w: World, points: U32, tickets: List<&2, Ticket>, live: List<&2, Ticket>,
            phase: Phase, earned: U32, served: U32, +rate: U32, stars: U32) -> Shift:
  match next:
    case (o, pay):
      Shift{w, points, tickets, live, phase, o, U32.add(earned, rated(pay, rate)), served, stars}

# The world after a frame. When the frame ran no tick, nothing new is judged.
def judged(moved: Bool, +w: World, +points: U32, +tickets: List<&2, Ticket>, +live: List<&2, Ticket>,
           +order: Order, +earned: U32, +served: U32, +stars: U32) -> Shift:
  match moved:
    case False{}:
      Shift{w, points, tickets, live, Running{}, order, earned, served, stars}
    case True{}:
      +now = tick_of(w)
      +live2 = judge(charges_of(w), live, now)
      +fresh = written(live2, now)
      +total = U32.add(points, points_in(fresh))
      +arrived = at_order(order, leg_of(w), along_of(w), speed_now(w), side_now(w))
      +done = Bool.and(arrived, order_was_aboard(order))
      +rate = stars_lost(stars, points_in(fresh))
      paid_up(served_on(arrived, seed_of(w), order, leg_of(w), along_of(w), now, served), w,
              total, append(fresh, tickets), live2, phase_after(crashed(w), total, now),
              earned, U32.add(served, Bool.to_u32(done)), rate,
              stars_after(rate, done, U32.is_lt(order_due(order), now)))

def drive_on(go: Bool, +s: Shift, +ms: U32, +input: Controls) -> Shift:
  match go:
    case False{}:
      s
    case True{}:
      match s:
        case Shift{drive, +points, +tickets, +live, phase, +order, +earned, +served, +stars}:
          +before = tick_of(drive)
          +w = advance(drive, ms, input)
          judged(U32.is_ne(tick_of(w), before), w, points, tickets, live, order, earned, served, stars)

def phase_of(s: Shift) -> Phase:
  match s:
    case Shift{drive, points, tickets, live, phase, order, earned, served, stars}:
      phase

def shift_advance(+s: Shift, +ms: U32, +input: Controls) -> Shift:
  drive_on(is_running(phase_of(s)), s, ms, input)

def drive_of(s: Shift) -> World:
  match s:
    case Shift{drive, points, tickets, live, phase, order, earned, served, stars}:
      drive

def points_of(s: Shift) -> U32:
  match s:
    case Shift{drive, points, tickets, live, phase, order, earned, served, stars}:
      points

def held_at() -> U32:
  Lic.held_at_points()

def points_of_rule(+id: U32) -> U32:
  R.points_of(id)

# Ticks left in the shift.
def clock_left(s: Shift) -> U32:
  +now = tick_of(drive_of(s))
  Bool.pick(U32, U32.is_lt(now, shift_ticks()), U32.sub(shift_ticks(), now), 0)

# Where the order waits or goes, on the ground, for the renderer.
def order_point(s: Shift) -> W.Pt:
  match s:
    case Shift{drive, points, tickets, live, phase, order, earned, served, stars}:
      stop_point(seed_of(drive), order)

# The worker's doors and networks go into the drive the shift carries.
def with_drive(s: Shift, w: World) -> Shift:
  match s:
    case Shift{drive, points, tickets, live, phase, order, earned, served, stars}:
      Shift{w, points, tickets, live, phase, order, earned, served, stars}

# The light the car drives toward, and the crossing it hangs at and the one
# behind it, for the renderer.
def light_state(+w: World) -> U32:
  light_ahead(leg_of(w), on_side(place_of(w)), seed_of(w), tick_of(w))

def light_node(+w: World) -> W.Pt:
  +l = leg_of(w)
  W.node(seed_of(w), toward_i(l), toward_j(l))

def back_i(l: Leg) -> U32:
  match l:
    case Leg{i, j, dir, length}:
      i
    case Cut{ci, cj, dir, t0, length}:
      ci

def back_j(l: Leg) -> U32:
  match l:
    case Leg{i, j, dir, length}:
      j
    case Cut{ci, cj, dir, t0, length}:
      cj

def light_back(+w: World) -> W.Pt:
  +l = leg_of(w)
  W.node(seed_of(w), back_i(l), back_j(l))

# The laws walk a whole cycle: at no point of it are both axes of a crossing
# green. A crossing's offset only shifts where in the cycle a tick falls.
def never_both_green(fuel: Nat, +t: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +ew = light_of(t)
      +ns = light_of(U32.mod(U32.add(t, U32.div(cycle_ticks(), 2)), cycle_ticks()))
      Bool.and(Bool.not(Bool.and(U32.is_eq(ew, 0), U32.is_eq(ns, 0))), never_both_green(p, U32.add(t, 1)))
