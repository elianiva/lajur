# lajur — the world: an endless lattice of main roads, cut into cells.
#
# Every cell is a function of (seed, i, j) alone. A cell can be made in any
# order, far ahead of the driver, and it meets its neighbours exactly, because
# a road between two cells is computed from the road's own key and never from
# either cell. Bend is pure, so that needs no law: it is how the code is built.
#
# Distances are centimetres; a signed one is a U32 read as two's complement.
# Positions along a curve or across a cell's frame are in 65536ths; rolls of a
# hash are in 1024ths.
#
# What the laws hold, for every seed:
#   - a crossing of the lattice keeps at least two of its four roads, so a main
#     road may bend at a crossing but never ends there;
#   - two collectors that meet a main road from either side either meet it at
#     one crossing or stand at least a fifth of the road apart;
#   - a lokal street is a residential road and a main road an urban one, with
#     the limits PM 111/2015 Pasal 3 ayat (4) sets;
#   - streets across a lane leave two rows of lots between them, and branches
#     leave a street at least the lokal floor apart, at every density.
#
# Every one of these turns on a decision that takes a handful of values (a
# drop, a mouth position, a road class, a level of density), so the laws walk
# every value the hash can pick, and no seed can break them. How a tree of
# streets wanders is geometry and is not a law: the lab's plan check counts
# its crossings instead.
import Base
import ../../bend/model.bend as M

# ===========================================================================
# Sizes
# ===========================================================================

# Centre to centre of the lattice of main roads.
def pitch_cm() -> U32:
  65000

# How far a crossing may move from its place on the lattice, each way.
def jitter_cm() -> U32:
  21000

# The closest two junctions may stand on a main road, and the spacing of the
# slots a lokal street may meet it at.
def gap_cm() -> U32:
  10000

def slot_cm() -> U32:
  13000

# Half the river's width.
def river_half_cm() -> U32:
  1400

# The value noise behind density repeats over cells this wide.
def density_cm() -> U32:
  150000

# ===========================================================================
# Signed centimetres
# ===========================================================================

def half_turn() -> U32:
  2147483648

def is_neg(+x: U32) -> Bool:
  U32.is_ge(x, half_turn())

def sabs(+x: U32) -> U32:
  Bool.pick(U32, is_neg(x), U32.sub(0, x), x)

def signed(+down: Bool, +x: U32) -> U32:
  Bool.pick(U32, down, U32.sub(0, x), x)

# Division toward zero.
def sdiv(+x: U32, +d: U32) -> U32:
  signed(is_neg(x), U32.div(sabs(x), d))

# Division toward minus infinity: the cell a coordinate falls in.
def sfloor(+x: U32, +d: U32) -> U32:
  Bool.pick(U32, is_neg(x),
    U32.sub(0, U32.div(U32.add(sabs(x), U32.sub(d, 1)), d)),
    U32.div(x, d))

def smod3(+x: U32) -> U32:
  Bool.pick(U32, is_neg(x), U32.mod(U32.sub(3, U32.mod(sabs(x), 3)), 3), U32.mod(x, 3))

# a * t / 65536 for a below 2^22, without passing 2^32 on the way.
def mul16(+a: U32, +t: U32) -> U32:
  U32.add(U32.shrn(U32.mul(a, U32.shrn(t, 10n)), 6n), U32.shrn(U32.mul(a, U32.and(t, 1023)), 16n))

def scale(+d: U32, +t: U32) -> U32:
  signed(is_neg(d), mul16(sabs(d), t))

def lerp(+a: U32, +b: U32, +t: U32) -> U32:
  U32.add(a, scale(U32.sub(b, a), t))

# ===========================================================================
# The hash
#
# The same mix the lab's TypeScript uses, folded over its arguments from the
# seed. A roll is its top ten bits, a number of 1024ths.
# ===========================================================================

def mix(+a: U32, +b: U32) -> U32:
  +h0 = U32.mul(U32.xor(a, U32.mul(b, 2654435761)), 2246822507)
  +h1 = U32.xor(h0, U32.shrn(h0, 13n))
  +h2 = U32.mul(h1, 3266489909)
  U32.xor(h2, U32.shrn(h2, 16n))

def hash2(+s: U32, +a: U32, +b: U32) -> U32:
  mix(mix(s, a), b)

def hash3(+s: U32, +a: U32, +b: U32, +c: U32) -> U32:
  mix(hash2(s, a, b), c)

def hash4(+s: U32, +a: U32, +b: U32, +c: U32, +d: U32) -> U32:
  mix(hash3(s, a, b, c), d)

def hash5(+s: U32, +a: U32, +b: U32, +c: U32, +d: U32, +e: U32) -> U32:
  mix(hash4(s, a, b, c, d), e)

def roll(+h: U32) -> U32:
  U32.shrn(h, 22n)

# ===========================================================================
# Points
# ===========================================================================

type Pt is Data:
  Pt{x: U32, z: U32}

def pt_add(p: Pt, q: Pt) -> Pt:
  match p:
    case Pt{px, pz}:
      match q:
        case Pt{qx, qz}:
          Pt{U32.add(px, qx), U32.add(pz, qz)}

def pt_sub(p: Pt, q: Pt) -> Pt:
  match p:
    case Pt{px, pz}:
      match q:
        case Pt{qx, qz}:
          Pt{U32.sub(px, qx), U32.sub(pz, qz)}

def pt_div(p: Pt, +d: U32) -> Pt:
  match p:
    case Pt{px, pz}:
      Pt{sdiv(px, d), sdiv(pz, d)}

def pt_lerp(p: Pt, q: Pt, +t: U32) -> Pt:
  match p:
    case Pt{px, pz}:
      match q:
        case Pt{qx, qz}:
          Pt{lerp(px, qx, t), lerp(pz, qz, t)}

# Integer square root by Newton's method from above, as in town.bend.
def root(fuel: Nat, +n: U32, +x: U32) -> U32:
  match fuel:
    case 0n:
      x
    case 1n+p:
      +next = U32.shrn(U32.add(x, U32.div(n, U32.max(x, 1))), 1n)
      root(p, n, Bool.pick(U32, U32.is_le(x, next), x, next))

def sqrt(+n: U32) -> U32:
  root(6n, n, U32.min(U32.shln(1, U32.to_nat(U32.shrn(U32.add(U32.from_nat(U32.log2(n)), 2), 1n))), 65535))

# The distance between two points, to four centimetres, for points up to
# 1.8 km apart.
def dist(p: Pt, q: Pt) -> U32:
  match p:
    case Pt{px, pz}:
      match q:
        case Pt{qx, qz}:
          +dx = U32.shrn(sabs(U32.sub(qx, px)), 2n)
          +dz = U32.shrn(sabs(U32.sub(qz, pz)), 2n)
          U32.mul(sqrt(U32.add(U32.mul(dx, dx), U32.mul(dz, dz))), 4)

# ===========================================================================
# Layer 1: the lattice
# ===========================================================================

# Where crossing (i, j) stands. Indices wrap like the coordinates, so the
# world runs on past zero in every direction.
def jit(+h: U32) -> U32:
  U32.sub(U32.shrn(U32.mul(U32.shrn(h, 16n), U32.mul(jitter_cm(), 2)), 16n), jitter_cm())

def node(+seed: U32, +i: U32, +j: U32) -> Pt:
  Pt{U32.add(U32.mul(i, pitch_cm()), jit(hash3(seed, 1, i, j))),
     U32.add(U32.mul(j, pitch_cm()), jit(hash3(seed, 2, i, j)))}

# A crossing may drop one of its four roads. Only a crossing with both
# indices even may, and no two such crossings are neighbours, so each road has
# one crossing that can drop it.
type Drop is Data:
  Keep{}
  DropEast{}
  DropWest{}
  DropNorth{}
  DropSouth{}

def drops_here(+i_even: Bool, +j_even: Bool) -> Bool:
  Bool.and(i_even, j_even)

def drop_of_roll(+r: U32) -> Drop:
  Bool.pick(Drop, U32.is_lt(r, 92), DropEast{},
  Bool.pick(Drop, U32.is_lt(r, 184), DropWest{},
  Bool.pick(Drop, U32.is_lt(r, 276), DropNorth{},
  Bool.pick(Drop, U32.is_lt(r, 369), DropSouth{}, Keep{}))))

def drop_if(here: Bool, +seed: U32, +i: U32, +j: U32) -> Drop:
  match here:
    case True{}:
      drop_of_roll(roll(hash3(seed, 3, i, j)))
    case False{}:
      Keep{}

def drop_at(+seed: U32, +i: U32, +j: U32) -> Drop:
  drop_if(drops_here(U32.is_even(i), U32.is_even(j)), seed, i, j)

def is_east(d: Drop) -> Bool:
  match d:
    case DropEast{}:
      True{}
    case _:
      False{}

def is_west(d: Drop) -> Bool:
  match d:
    case DropWest{}:
      True{}
    case _:
      False{}

def is_north(d: Drop) -> Bool:
  match d:
    case DropNorth{}:
      True{}
    case _:
      False{}

def is_south(d: Drop) -> Bool:
  match d:
    case DropSouth{}:
      True{}
    case _:
      False{}

# Whether the road from one crossing to the next, east or south of it, is
# dropped by either end.
def cut_between(+near: Drop, +far: Drop, east: Bool) -> Bool:
  match east:
    case True{}:
      Bool.or(is_east(near), is_west(far))
    case False{}:
      Bool.or(is_south(near), is_north(far))

def step_i(+i: U32, +east: Bool) -> U32:
  Bool.pick(U32, east, U32.add(i, 1), i)

def step_j(+j: U32, +east: Bool) -> U32:
  Bool.pick(U32, east, j, U32.add(j, 1))

# The road from (i, j) east to (i + 1, j), or south to (i, j + 1).
def has_road(+seed: U32, +i: U32, +j: U32, +east: Bool) -> Bool:
  Bool.not(cut_between(drop_at(seed, i, j), drop_at(seed, step_i(i, east), step_j(j, east)), east))

type Class is Data:
  Arterial{}
  Collector{}
  Lokal{}

# Every third line of the lattice is an arterial; the rest are collectors.
def road_class(+i: U32, +j: U32, +east: Bool) -> Class:
  Bool.pick(Class, U32.is_eq(smod3(Bool.pick(U32, east, j, i)), 0), Arterial{}, Collector{})

def class_code(c: Class) -> U32:
  match c:
    case Arterial{}:
      1
    case Collector{}:
      2
    case Lokal{}:
      3

def road_code(+i: U32, +j: U32, +east: Bool) -> U32:
  class_code(road_class(i, j, east))

# A main road carries the urban limit and a lokal street the residential one.
def zone_of(c: Class) -> M.Zone:
  match c:
    case Arterial{}:
      M.Urban{}
    case Collector{}:
      M.Urban{}
    case Lokal{}:
      M.Residential{}

def limit_of(c: Class) -> U32:
  M.speed_limit(zone_of(c))

# ===========================================================================
# Curves: each road a Catmull-Rom segment through the lattice
# ===========================================================================

type Curve is Data:
  Curve{p1: Pt, b: Pt, c: Pt, p2: Pt}

def curve_of(+seed: U32, +i: U32, +j: U32, +east: Bool) -> Curve:
  +di = Bool.pick(U32, east, 1, 0)
  +dj = Bool.pick(U32, east, 0, 1)
  +p0 = node(seed, U32.sub(i, di), U32.sub(j, dj))
  +p1 = node(seed, i, j)
  +p2 = node(seed, U32.add(i, di), U32.add(j, dj))
  +p3 = node(seed, U32.add(i, U32.mul(di, 2)), U32.add(j, U32.mul(dj, 2)))
  Curve{p1, pt_add(p1, pt_div(pt_sub(p2, p0), 6)), pt_sub(p2, pt_div(pt_sub(p3, p1), 6)), p2}

# A point along a curve, t in 65536ths, by de Casteljau, so every product
# stays a difference of nearby points.
def curve_at(k: Curve, +t: U32) -> Pt:
  match k:
    case Curve{+a, +b, +c, +e}:
      +ab = pt_lerp(a, b, t)
      +bc = pt_lerp(b, c, t)
      +ce = pt_lerp(c, e, t)
      pt_lerp(pt_lerp(ab, bc, t), pt_lerp(bc, ce, t), t)

def curve_point(+seed: U32, +i: U32, +j: U32, +east: Bool, +t: U32) -> Pt:
  curve_at(curve_of(seed, i, j, east), t)

# A curve's length, from 32 chords. Both cells beside a road measure it alike.
def chords(fuel: Nat, +k: Curve, +step: U32, +prev: Pt, +acc: U32) -> U32:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +next = curve_at(k, U32.add(U32.mul(step, 2048), 2048))
      chords(p, k, U32.add(step, 1), next, U32.add(acc, dist(prev, next)))

def curve_length(+k: Curve) -> U32:
  chords(32n, k, 0, curve_at(k, 0), 0)

def road_length(+seed: U32, +i: U32, +j: U32, +east: Bool) -> U32:
  curve_length(curve_of(seed, i, j, east))

# ===========================================================================
# Layer 2: a cell's frame, a Coons patch of its four roads
# ===========================================================================

type Frame is Data:
  Frame{a: Pt, s: Curve, n: Curve, w: Curve, e: Curve, mu: U32, mv: U32}

def corner(k: Curve, +last: Bool) -> Pt:
  match k:
    case Curve{p1, b, c, p2}:
      Bool.pick(Pt, last, p2, p1)

def frame_of(+seed: U32, +i: U32, +j: U32) -> Frame:
  +s = curve_of(seed, i, j, True{})
  +n = curve_of(seed, i, U32.add(j, 1), True{})
  +w = curve_of(seed, i, j, False{})
  +e = curve_of(seed, U32.add(i, 1), j, False{})
  +a = corner(s, False{})
  +b = corner(s, True{})
  +c = corner(n, True{})
  +d = corner(n, False{})
  # Metres a unit of u and of v spans, from the chords, in centimetres.
  Frame{a, s, n, w, e, U32.shrn(U32.add(dist(a, b), dist(d, c)), 1n), U32.shrn(U32.add(dist(a, d), dist(b, c)), 1n)}

def frame_mu(f: Frame) -> U32:
  match f:
    case Frame{a, s, n, w, e, mu, mv}:
      mu

def frame_mv(f: Frame) -> U32:
  match f:
    case Frame{a, s, n, w, e, mu, mv}:
      mv

# The point at (u, v), both in 65536ths, all of it measured from the frame's
# first corner so no product runs past 2^31.
def frame_at(f: Frame, +u: U32, +v: U32) -> Pt:
  match f:
    case Frame{+a, +s, +n, +w, +e, mu, mv}:
      +sa = pt_sub(curve_at(s, u), a)
      +na = pt_sub(curve_at(n, u), a)
      +wa = pt_sub(curve_at(w, v), a)
      +ea = pt_sub(curve_at(e, v), a)
      +o = {Pt{0, 0} : Pt}
      +ba = pt_sub(corner(s, True{}), a)
      +ca = pt_sub(corner(n, True{}), a)
      +da = pt_sub(corner(n, False{}), a)
      +bil = pt_lerp(pt_lerp(o, ba, u), pt_lerp(da, ca, u), v)
      pt_add(a, pt_sub(pt_add(pt_lerp(sa, na, v), pt_lerp(wa, ea, u)), bil))

# A line across the frame at a fixed u (or v), measured by 32 chords.
def frame_chords(fuel: Nat, +f: Frame, +fixed_u: Bool, +at: U32, +step: U32, +prev: Pt, +acc: U32) -> U32:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +t = U32.add(U32.mul(step, 2048), 2048)
      +next = frame_at(f, Bool.pick(U32, fixed_u, at, t), Bool.pick(U32, fixed_u, t, at))
      frame_chords(p, f, fixed_u, at, U32.add(step, 1), next, U32.add(acc, dist(prev, next)))

def frame_line_length(+f: Frame, +fixed_u: Bool, +at: U32) -> U32:
  frame_chords(32n, f, fixed_u, at, 0, frame_at(f, Bool.pick(U32, fixed_u, at, 0), Bool.pick(U32, fixed_u, 0, at)), 0)

# Centimetres along the same line to t, by the same chords, the one across t
# cut short there.
def frame_chords_to(fuel: Nat, +f: Frame, +fixed_u: Bool, +at: U32, +step: U32, +t: U32, +prev: Pt, +acc: U32) -> U32:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +s = U32.min(U32.mul(U32.add(step, 1), 2048), t)
      +next = frame_at(f, Bool.pick(U32, fixed_u, at, s), Bool.pick(U32, fixed_u, s, at))
      frame_chords_to(p, f, fixed_u, at, U32.add(step, 1), t, next, U32.add(acc, dist(prev, next)))

def frame_to(+f: Frame, +fixed_u: Bool, +at: U32, +t: U32) -> U32:
  frame_chords_to(32n, f, fixed_u, at, 0, t, frame_at(f, Bool.pick(U32, fixed_u, at, 0), Bool.pick(U32, fixed_u, 0, at)), 0)

# ===========================================================================
# Density: value noise over the world, in 1024ths
# ===========================================================================

def smooth(+t: U32) -> U32:
  U32.shrn(U32.mul(U32.mul(t, t), U32.sub(3072, U32.mul(t, 2))), 20n)

def lerp10(+a: U32, +b: U32, +t: U32) -> U32:
  U32.add(a, sdiv(U32.mul(U32.sub(b, a), t), 1024))

def corner_density(+seed: U32, +i: U32, +j: U32) -> U32:
  roll(hash3(seed, 77, i, j))

def density(+seed: U32, +x: U32, +z: U32) -> U32:
  +g = density_cm()
  +i = sfloor(x, g)
  +j = sfloor(z, g)
  +u = smooth(U32.div(U32.mul(U32.sub(x, U32.mul(i, g)), 128), 18750))
  +v = smooth(U32.div(U32.mul(U32.sub(z, U32.mul(j, g)), 128), 18750))
  +i1 = U32.add(i, 1)
  +j1 = U32.add(j, 1)
  lerp10(lerp10(corner_density(seed, i, j), corner_density(seed, i1, j), u),
         lerp10(corner_density(seed, i, j1), corner_density(seed, i1, j1), u), v)

def cell_density(+seed: U32, +i: U32, +j: U32) -> U32:
  +h = U32.shrn(pitch_cm(), 1n)
  density(seed, U32.add(U32.mul(i, pitch_cm()), h), U32.add(U32.mul(j, pitch_cm()), h))

# ===========================================================================
# Rivers: along every fourth row of cells, mid-cell
# ===========================================================================

def river_row(+j: U32) -> Bool:
  U32.is_eq(U32.and(j, 3), 2)

# Where the water runs across the cell, as v in 65536ths, for u in 65536ths.
# The wiggle is a function of the global column, so it meets itself.
def river_v(+seed: U32, +i: U32, +j: U32, +u: U32) -> U32:
  +l = lerp10(roll(hash3(seed, 5, i, j)), roll(hash3(seed, 5, U32.add(i, 1), j)), smooth(U32.shrn(u, 6n)))
  U32.add(32768, sdiv(U32.mul(9175, U32.sub(U32.mul(l, 2), 1024)), 1024))

# ===========================================================================
# Collectors across a cell
#
# A collector meets a main road at a mouth. The mouth's place comes from the
# road alone: one of eight places per column (or row), so a collector meets
# the roads at both its ends at the same u and carries on into the next cell.
# The cell across the road uses the same place, a crossing, or the mirror of
# it, a stagger.
# ===========================================================================

# The eight places a mouth can take, in 1024ths of the road.
def mouth_at(+k: U32) -> U32:
  U32.add(338, U32.mul(k, 10))

def mouths() -> U32:
  8

# Side 0 is the cell south (or west) of the road, side 1 north (or east).
def side_mouth(+seed: U32, +i: U32, +j: U32, +east: Bool, +side: U32) -> U32:
  +f = mouth_at(U32.shrn(hash3(seed, 6, Bool.pick(U32, east, i, 0), Bool.pick(U32, east, 0, j)), 29n))
  +aligned = U32.is_lt(roll(hash4(seed, 7, i, j, Bool.pick(U32, east, 0, 1))), 614)
  U32.mul(Bool.pick(U32, Bool.or(U32.is_eq(side, 0), aligned), f, U32.sub(1024, f)), 64)

type Cuts is Data:
  Cuts{uc: U32, vc: U32}

# 0 is no cut: a cut always sits well inside the cell.
def cut_u(+seed: U32, +i: U32, +j: U32, +want: U32) -> U32:
  +a = side_mouth(seed, i, j, True{}, 1)
  +ok = Bool.and(U32.is_lt(roll(hash3(seed, 8, i, j)), want),
        Bool.and(has_road(seed, i, j, True{}),
        Bool.and(has_road(seed, i, U32.add(j, 1), True{}),
                 U32.is_eq(a, side_mouth(seed, i, U32.add(j, 1), True{}, 0)))))
  Bool.pick(U32, ok, a, 0)

def cut_v(+seed: U32, +i: U32, +j: U32, +want: U32) -> U32:
  +a = side_mouth(seed, i, j, False{}, 1)
  +ok = Bool.and(Bool.not(river_row(j)),
        Bool.and(U32.is_lt(roll(hash3(seed, 9, i, j)), U32.div(U32.mul(want, 717), 1024)),
        Bool.and(has_road(seed, i, j, False{}),
        Bool.and(has_road(seed, U32.add(i, 1), j, False{}),
                 U32.is_eq(a, side_mouth(seed, U32.add(i, 1), j, False{}, 0))))))
  Bool.pick(U32, ok, a, 0)

def cell_cuts(+seed: U32, +i: U32, +j: U32) -> Cuts:
  +want = U32.add(358, U32.shrn(cell_density(seed, i, j), 1n))
  Cuts{cut_u(seed, i, j, want), cut_v(seed, i, j, want)}

def cuts_u(c: Cuts) -> U32:
  match c:
    case Cuts{uc, vc}:
      uc

def cuts_v(c: Cuts) -> U32:
  match c:
    case Cuts{uc, vc}:
      vc

# ===========================================================================
# Entrance slots
#
# Where a lokal street may meet a main road or a collector: every 130 m from a
# point the road's key picks, kept 100 m from the road's ends and from the
# junctions already on it. Both sides of the road compute the same list, so a
# street from one side either lines up with one from the other or is a slot
# apart. Positions are in 65536ths of the road; `avoid` may be past 65536 to
# avoid nothing.
# ===========================================================================

def clear_of(+m: U32, +len: U32, +a: U32) -> Bool:
  +at = mul16(len, U32.min(a, 65536))
  Bool.or(U32.is_gt(a, 65536), U32.is_ge(sabs(U32.sub(at, m)), gap_cm()))

def slot_walk(fuel: Nat, +m: U32, +len: U32, +a0: U32, +a1: U32) -> List<&2, U32>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+p:
      +inside = U32.is_lt(U32.add(m, gap_cm()), len)
      +rest = slot_walk(p, U32.add(m, slot_cm()), len, a0, a1)
      +keep = Bool.and(inside, Bool.and(clear_of(m, len, a0), clear_of(m, len, a1)))
      Bool.pick(List<&2, U32>, keep, U32.mul(U32.div(U32.mul(m, 4096), len), 16) <> rest, rest)

def slots(+seed: U32, +k0: U32, +k1: U32, +k2: U32, +len: U32, +a0: U32, +a1: U32) -> List<&2, U32>:
  +off = U32.shrn(U32.mul(U32.shrn(hash4(seed, 10, k0, k1, k2), 16n), slot_cm()), 16n)
  slot_walk(16n, U32.add(gap_cm(), off), len, a0, a1)

# ===========================================================================
# Layer 3: what a block becomes
#
# From the block's density and its own roll, both in 1024ths. Sawah gives way
# to kebun and kampung as the town thickens; a ring is a civic court.
# ===========================================================================

type Land is Data:
  Sawah{}
  Kebun{}
  Tree{}
  Comb{}
  Grid{}
  Ring{}

def land_of(+d: U32, +r: U32) -> Land:
  Bool.pick(Land, U32.is_lt(d, 154), Bool.pick(Land, U32.is_lt(r, 768), Sawah{}, Kebun{}),
  Bool.pick(Land, U32.is_lt(d, 410),
    Bool.pick(Land, U32.is_lt(r, 461), Tree{}, Bool.pick(Land, U32.is_lt(r, 635), Kebun{},
      Bool.pick(Land, U32.is_lt(r, 737), Ring{}, Sawah{}))),
  Bool.pick(Land, U32.is_lt(d, 635),
    Bool.pick(Land, U32.is_lt(r, 512), Tree{}, Bool.pick(Land, U32.is_lt(r, 799), Comb{}, Ring{})),
    Bool.pick(Land, U32.is_lt(r, 358), Grid{}, Bool.pick(Land, U32.is_lt(r, 666), Tree{},
      Bool.pick(Land, U32.is_lt(r, 840), Comb{}, Ring{}))))))

def land_code(l: Land) -> U32:
  match l:
    case Sawah{}:
      0
    case Kebun{}:
      1
    case Tree{}:
      2
    case Comb{}:
      3
    case Grid{}:
      4
    case Ring{}:
      5

def land(+d: U32, +r: U32) -> U32:
  land_code(land_of(d, r))

# A ring's court: a pasar, an alun-alun or a sekolah in town, and a gudang yard
# in place of the pasar out in the fields.
def court(+d: U32, +r: U32) -> U32:
  Bool.pick(U32, U32.is_gt(d, 614),
    Bool.pick(U32, U32.is_lt(r, 410), 1, Bool.pick(U32, U32.is_lt(r, 768), 0, 2)),
    Bool.pick(U32, U32.is_lt(r, 307), 0, Bool.pick(U32, U32.is_lt(r, 717), 2, 3)))

# ===========================================================================
# For the laws
# ===========================================================================

# How many of a crossing's four roads stay, given what it and each neighbour
# drop.
def count(+b: Bool) -> U32:
  Bool.pick(U32, b, 1, 0)

def kept(+own: Drop, +w: Drop, +e: Drop, +n: Drop, +s: Drop) -> U32:
  U32.add(U32.add(count(Bool.not(cut_between(own, e, True{}))), count(Bool.not(cut_between(w, own, True{})))),
          U32.add(count(Bool.not(cut_between(own, s, False{}))), count(Bool.not(cut_between(n, own, False{})))))

# Every drop a crossing may make: all five where drops_here allows, else none.
def options(here: Bool) -> List<&2, Drop>:
  match here:
    case True{}:
      [Keep{}, DropEast{}, DropWest{}, DropNorth{}, DropSouth{}]
    case False{}:
      [Keep{}]

def keeps_s(ss: List<&2, Drop>, +own: Drop, +w: Drop, +e: Drop, +n: Drop) -> Bool:
  match ss:
    case Nil{}:
      True{}
    case Con{+s, t}:
      Bool.and(U32.is_ge(kept(own, w, e, n, s), 2), keeps_s(t, own, w, e, n))

def keeps_n(ns: List<&2, Drop>, +ss: List<&2, Drop>, +own: Drop, +w: Drop, +e: Drop) -> Bool:
  match ns:
    case Nil{}:
      True{}
    case Con{+n, t}:
      Bool.and(keeps_s(ss, own, w, e, n), keeps_n(t, ss, own, w, e))

def keeps_e(es: List<&2, Drop>, +ns: List<&2, Drop>, +ss: List<&2, Drop>, +own: Drop, +w: Drop) -> Bool:
  match es:
    case Nil{}:
      True{}
    case Con{+e, t}:
      Bool.and(keeps_n(ns, ss, own, w, e), keeps_e(t, ns, ss, own, w))

def keeps_w(ws: List<&2, Drop>, +es: List<&2, Drop>, +ns: List<&2, Drop>, +ss: List<&2, Drop>, +own: Drop) -> Bool:
  match ws:
    case Nil{}:
      True{}
    case Con{+w, t}:
      Bool.and(keeps_e(es, ns, ss, own, w), keeps_w(t, es, ns, ss, own))

def keeps_own(owns: List<&2, Drop>, +ws: List<&2, Drop>, +es: List<&2, Drop>, +ns: List<&2, Drop>, +ss: List<&2, Drop>) -> Bool:
  match owns:
    case Nil{}:
      True{}
    case Con{+own, t}:
      Bool.and(keeps_w(ws, es, ns, ss, own), keeps_own(t, ws, es, ns, ss))

# A crossing whose indices have the given parities, against every drop it and
# its four neighbours may make. A neighbour east or west flips the parity of
# i, one north or south the parity of j.
def crossing_keeps_two(+ie: Bool, +je: Bool) -> Bool:
  +side = options(drops_here(Bool.not(ie), je))
  +ends = options(drops_here(ie, Bool.not(je)))
  keeps_own(options(drops_here(ie, je)), side, side, ends, ends)

def every_crossing_keeps_two() -> Bool:
  Bool.and(Bool.and(crossing_keeps_two(True{}, True{}), crossing_keeps_two(True{}, False{})),
           Bool.and(crossing_keeps_two(False{}, True{}), crossing_keeps_two(False{}, False{})))

# The stagger a mouth place leaves against its mirror; none if it is past half.
def stagger_of(+f: U32) -> U32:
  Bool.pick(U32, U32.is_lt(U32.mul(f, 2), 1024), U32.sub(1024, U32.mul(f, 2)), 0)

# The narrowest stagger any mouth place leaves, in 1024ths of the road.
def stagger_walk(fuel: Nat, +k: U32, +least: U32) -> U32:
  match fuel:
    case 0n:
      least
    case 1n+p:
      stagger_walk(p, U32.add(k, 1), U32.min(least, stagger_of(mouth_at(k))))

def narrowest_stagger() -> U32:
  stagger_walk(U32.to_nat(mouths()), 0, 1024)

# ===========================================================================
# Layer 3: the streets inside a block
#
# Everything here works in the block's own metric frame: x = u * mu and
# z = v * mv, in centimetres from the frame's first corner. The lab maps a
# point back with the frame, so a street straight here bends with the frame.
# Headings are in 65536ths of a turn; sines and cosines in 16384ths.
# ===========================================================================

# Signed comparisons and bounds, on U32 read as two's complement.
def slt(+a: U32, +b: U32) -> Bool:
  U32.is_lt(U32.xor(a, half_turn()), U32.xor(b, half_turn()))

def smin(+a: U32, +b: U32) -> U32:
  Bool.pick(U32, slt(a, b), a, b)

def smax(+a: U32, +b: U32) -> U32:
  Bool.pick(U32, slt(a, b), b, a)

def clamp(+x: U32, +lo: U32, +hi: U32) -> U32:
  smin(smax(x, lo), hi)

# Bhaskara's sine, good to a fifth of a degree.
def sin14(+a: U32) -> U32:
  +h = U32.and(a, 65535)
  +x = U32.shrn(U32.and(h, 32767), 4n)
  +p = U32.mul(x, U32.sub(2048, x))
  signed(U32.is_ge(h, 32768), U32.div(U32.mul(p, 256), U32.shrn(U32.sub(20971520, U32.mul(p, 4)), 10n)))

def cos14(+a: U32) -> U32:
  sin14(U32.add(a, 16384))

# The heading from the origin to (dx, dz), to a quarter of a degree.
def atan2(+dz: U32, +dx: U32) -> U32:
  +ax = sabs(dx)
  +az = sabs(dz)
  +mx = U32.max(U32.max(ax, az), 1)
  +t = U32.mul(U32.div(U32.mul(U32.min(ax, az), 4096), mx), 16)
  +r0 = U32.add(U32.shrn(t, 3n), mul16(2847, mul16(t, U32.sub(65536, t))))
  +r1 = Bool.pick(U32, U32.is_gt(az, ax), U32.sub(16384, r0), r0)
  +r2 = Bool.pick(U32, is_neg(dx), U32.sub(32768, r1), r1)
  U32.and(Bool.pick(U32, is_neg(dz), U32.sub(65536, r2), r2), 65535)

# How far heading a turns past heading b, signed, within half a turn.
def turn_from(+a: U32, +b: U32) -> U32:
  U32.sub(U32.and(U32.add(U32.sub(a, b), 32768), 65535), 32768)

# A roll in 65536ths: the n-th of a stream the key picks.
def draw(+key: U32, +n: U32) -> U32:
  U32.shrn(mix(key, n), 16n)

# lo + (hi - lo) * r for a roll r in 65536ths.
def between(+lo: U32, +hi: U32, +r: U32) -> U32:
  U32.add(lo, mul16(U32.sub(hi, lo), r))

def hash6(+s: U32, +a: U32, +b: U32, +c: U32, +d: U32, +e: U32, +f: U32) -> U32:
  mix(hash5(s, a, b, c, d, e), f)

def pt_x(p: Pt) -> U32:
  match p:
    case Pt{x, z}:
      x

def pt_z(p: Pt) -> U32:
  match p:
    case Pt{x, z}:
      z

# Whether two points stand closer than r, for r below 2^15.
def within(p: Pt, q: Pt, +r: U32) -> Bool:
  match p:
    case Pt{px, pz}:
      match q:
        case Pt{qx, qz}:
          +dx = sabs(U32.sub(qx, px))
          +dz = sabs(U32.sub(qz, pz))
          Bool.and(Bool.and(U32.is_lt(dx, r), U32.is_lt(dz, r)),
            U32.is_lt(U32.add(U32.mul(U32.min(dx, r), U32.min(dx, r)), U32.mul(U32.min(dz, r), U32.min(dz, r))), U32.mul(r, r)))

# ---- What a block holds and hands back ------------------------------------

# A road along one side of a block: its key, its length, the junctions
# already on it, and the stretch of it the block owns, in 65536ths.
type Edge is Data:
  Edge{road: Bool, k0: U32, k1: U32, k2: U32, len: U32, a0: U32, a1: U32, t0: U32, t1: U32}

# A rectangle of the block's metric frame, centimetres.
type Box is Data:
  Box{x0: U32, x1: U32, z0: U32, z1: U32}

# An entrance: the side it is on (0 S, 1 N, 2 W, 3 E), where along the road
# (65536ths) and along the frame (cm), and the rolls that rank it.
type Slot is Data:
  Slot{side: U32, t: U32, at: U32, use: U32, shared: U32, own: U32}

type Mouth is Data:
  Mouth{side: U32, t: U32}

# A street: 0 a tree street, 1 a ring lane, 2 a mouth, 3 a cross street.
type Street is Data:
  Street{tag: U32, bulb: Bool, pts: List<&2, Pt>}

type Placed is Data:
  Placed{p: Pt, id: U32}

def box_x0(+b: Box) -> U32:
  match b:
    case Box{x0, x1, z0, z1}:
      x0

def box_x1(+b: Box) -> U32:
  match b:
    case Box{x0, x1, z0, z1}:
      x1

def box_z0(+b: Box) -> U32:
  match b:
    case Box{x0, x1, z0, z1}:
      z0

def box_z1(+b: Box) -> U32:
  match b:
    case Box{x0, x1, z0, z1}:
      z1

def box_w(+b: Box) -> U32:
  U32.sub(box_x1(b), box_x0(b))

def box_h(+b: Box) -> U32:
  U32.sub(box_z1(b), box_z0(b))

# Whether a box is at least `least` across both ways.
def roomy(+b: Box, +least: U32) -> Bool:
  Bool.and(Bool.not(slt(box_w(b), least)), Bool.not(slt(box_h(b), least)))

def inside(+b: Box, +x: U32, +z: U32) -> Bool:
  Bool.and(Bool.and(slt(box_x0(b), x), slt(x, box_x1(b))), Bool.and(slt(box_z0(b), z), slt(z, box_z1(b))))

def slot_side(+s: Slot) -> U32:
  match s:
    case Slot{side, t, at, use, shared, own}:
      side

def slot_t(+s: Slot) -> U32:
  match s:
    case Slot{side, t, at, use, shared, own}:
      t

def slot_at(+s: Slot) -> U32:
  match s:
    case Slot{side, t, at, use, shared, own}:
      at

def slot_use(+s: Slot) -> U32:
  match s:
    case Slot{side, t, at, use, shared, own}:
      use

def slot_le(+a: Slot, +b: Slot) -> Bool:
  U32.is_le(slot_use(a), slot_use(b))

# S and N run along u, W and E along v.
def along_u(+side: U32) -> Bool:
  U32.is_lt(side, 2)

# ---- Entrances --------------------------------------------------------------

# Whether a box reaches the side of the block's inner rectangle.
def touches(+side: U32, +bx: Box, +inner: Box) -> Bool:
  Bool.pick(Bool, U32.is_eq(side, 0), U32.is_eq(box_z0(bx), box_z0(inner)),
  Bool.pick(Bool, U32.is_eq(side, 1), U32.is_eq(box_z1(bx), box_z1(inner)),
  Bool.pick(Bool, U32.is_eq(side, 2), U32.is_eq(box_x0(bx), box_x0(inner)),
    U32.is_eq(box_x1(bx), box_x1(inner)))))

# The lokal floor: no entrance nearer than 20 m to a corner of the box.
def lok_floor_cm() -> U32:
  2000

def keep_slots(ts: List<&2, U32>, +seed: U32, +side: U32, +k0: U32, +k1: U32, +k2: U32, +t0: U32, +t1: U32, +m: U32, +lo: U32, +hi: U32) -> List<&2, Slot>:
  match ts:
    case Nil{}:
      Nil{}
    case Con{+t, r}:
      +rest = keep_slots(r, seed, side, k0, k1, k2, t0, t1, m, lo, hi)
      +at = mul16(m, t)
      +ok = Bool.and(Bool.and(U32.is_ge(t, t0), U32.is_le(t, t1)),
            Bool.and(Bool.not(slt(at, U32.add(lo, lok_floor_cm()))), Bool.not(slt(U32.sub(hi, lok_floor_cm()), at))))
      +shared = U32.shrn(hash5(seed, 13, k0, k1, k2, t), 16n)
      +own = U32.shrn(hash6(seed, 12, k0, k1, k2, t, Bool.pick(U32, U32.is_even(side), 1, 0)), 16n)
      Bool.pick(List<&2, Slot>, ok, Slot{side, t, at, U32.min(shared, own), shared, own} <> rest, rest)

def side_slots_go(go: Bool, +seed: U32, +side: U32, +e: Edge, +bx: Box, +mu: U32, +mv: U32) -> List<&2, Slot>:
  match go:
    case False{}:
      Nil{}
    case True{}:
      match e:
        case Edge{road, k0, k1, k2, len, a0, a1, t0, t1}:
          +u = along_u(side)
          keep_slots(slots(seed, k0, k1, k2, len, a0, a1), seed, side, k0, k1, k2, t0, t1,
            Bool.pick(U32, u, mu, mv), Bool.pick(U32, u, box_x0(bx), box_z0(bx)), Bool.pick(U32, u, box_x1(bx), box_z1(bx)))

def edge_road(+e: Edge) -> Bool:
  match e:
    case Edge{road, k0, k1, k2, len, a0, a1, t0, t1}:
      road

def side_slots(+seed: U32, +side: U32, +e: Edge, +bx: Box, +inner: Box, +mu: U32, +mv: U32) -> List<&2, Slot>:
  side_slots_go(Bool.and(edge_road(e), touches(side, bx, inner)), seed, side, e, bx, mu, mv)

def sort_slots(xs: List<&2, Slot>) -> List<&2, Slot>:
  List.sort(~Slot, ~(a => b => slot_le(a, b)), xs)

# The entrances into a box of the block: slots on each road side it reaches,
# most wanted first.
def entrances(+seed: U32, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge, +bx: Box, +inner: Box, +mu: U32, +mv: U32) -> List<&2, Slot>:
  sort_slots(List.append(&2, Slot, List.append(&2, Slot, side_slots(seed, 0, es, bx, inner, mu, mv), side_slots(seed, 1, en, bx, inner, mu, mv)),
    List.append(&2, Slot, side_slots(seed, 2, ew, bx, inner, mu, mv), side_slots(seed, 3, ee, bx, inner, mu, mv))))

# A slot both sides of the road like becomes a crossing of it: the most wanted
# entrance, and every other one with a low shared or own roll.
def liked(+s: Slot) -> Bool:
  match s:
    case Slot{side, t, at, use, shared, own}:
      Bool.or(U32.is_lt(shared, 19661), U32.is_lt(own, 14418))

def wanted(xs: List<&2, Slot>) -> List<&2, Slot>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+s, r}:
      +rest = wanted(r)
      Bool.pick(List<&2, Slot>, liked(s), s <> rest, rest)

def pick_used(xs: List<&2, Slot>) -> List<&2, Slot>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{s, r}:
      s <> wanted(r)

# ---- A tree of streets ----------------------------------------------------
#
# A trunk from each entrance, and branches that leave it at an angle, wander,
# and branch again. Growth stops where a street would come within two lot
# depths (26 m) of another, or leave the box. A tip that stops near another
# street links to it, a T, when the link is short and clear; otherwise it
# ends in a turning circle. The first trunk runs through to an entrance on
# another road when it can, so the tree is also a way through the block.
#
# Bend has no mutual recursion, so the growth is one loop over a stack of
# tasks: grow a street, then each of its branch points in turn, each branch
# grown in full before the next point, as a recursive grower would.

def clear_cm() -> U32:
  2600

def step_cm() -> U32:
  600

def none_id() -> U32:
  4294967295

type Entry is Data:
  Entry{start: Pt, end: Pt, h: U32}

# Where an entrance's street leaves the block's edge, where it reaches the
# box, and which way it faces inward.
def entry(+outer: Box, +bx: Box, +s: Slot) -> Entry:
  +side = slot_side(s)
  +at = slot_at(s)
  Bool.pick(Entry, U32.is_eq(side, 0), Entry{Pt{at, box_z0(outer)}, Pt{at, box_z0(bx)}, 16384},
  Bool.pick(Entry, U32.is_eq(side, 1), Entry{Pt{at, box_z1(outer)}, Pt{at, box_z1(bx)}, 49152},
  Bool.pick(Entry, U32.is_eq(side, 2), Entry{Pt{box_x0(outer), at}, Pt{box_x0(bx), at}, 0},
    Entry{Pt{box_x1(outer), at}, Pt{box_x1(bx), at}, 32768})))

def entry_start(+e: Entry) -> Pt:
  match e:
    case Entry{start, end, h}:
      start

def entry_end(+e: Entry) -> Pt:
  match e:
    case Entry{start, end, h}:
      end

def entry_h(+e: Entry) -> U32:
  match e:
    case Entry{start, end, h}:
      h

def has_mouth(ms: List<&2, Mouth>, +side: U32, +t: U32) -> Bool:
  match ms:
    case Nil{}:
      False{}
    case Con{+m, r}:
      match m:
        case Mouth{ms_side, ms_t}:
          Bool.or(Bool.and(U32.is_eq(ms_side, side), U32.is_eq(ms_t, t)), has_mouth(r, side, t))

# A junction keeps 24 m from every other one.
def room_at(js: List<&2, Pt>, +p: Pt) -> Bool:
  match js:
    case Nil{}:
      True{}
    case Con{+q, r}:
      Bool.and(Bool.not(within(p, q, 2400)), room_at(r, p))

def placed_id(+q: Placed) -> U32:
  match q:
    case Placed{p, id}:
      id

def placed_p(+q: Placed) -> Pt:
  match q:
    case Placed{p, id}:
      p

# Whether a street point would come within 26 m of a street already placed,
# leaving out the stretch of the parent it grew from.
def hit(qs: List<&2, Placed>, +p: Pt, +parent: U32, +from: Pt) -> Bool:
  match qs:
    case Nil{}:
      False{}
    case Con{+q, r}:
      +own = Bool.and(U32.is_eq(placed_id(q), parent), within(placed_p(q), from, 3900))
      Bool.or(Bool.and(Bool.not(own), within(p, placed_p(q), clear_cm())), hit(r, p, parent, from))

type Near is Data:
  Near{found: Bool, p: Pt, id: U32, d: U32}

# The nearest placed point within 80 m, not on the parent.
def nearest(qs: List<&2, Placed>, +tip: Pt, +parent: U32, +best: Near) -> Near:
  match qs:
    case Nil{}:
      best
    case Con{+q, r}:
      match best:
        case Near{found, bp, bid, bd}:
          +dd = dist(tip, placed_p(q))
          +ok = Bool.and(Bool.and(U32.is_ne(placed_id(q), parent), within(tip, placed_p(q), 8000)),
                Bool.or(Bool.not(found), U32.is_lt(dd, bd)))
          nearest(r, tip, parent, Bool.pick(Near, ok, Near{True{}, placed_p(q), placed_id(q), dd}, Near{found, bp, bid, bd}))

# Whether a link from the tip to the midpoint would pass near another street.
def crossing(qs: List<&2, Placed>, +mid: Pt, +r: U32, +skip: U32) -> Bool:
  match qs:
    case Nil{}:
      False{}
    case Con{+q, rest}:
      Bool.or(Bool.and(U32.is_ne(placed_id(q), skip), within(placed_p(q), mid, r)), crossing(rest, mid, r, skip))

def place_all(ps: List<&2, Pt>, +id: U32, acc: List<&2, Placed>) -> List<&2, Placed>:
  match ps:
    case Nil{}:
      acc
    case Con{p, r}:
      place_all(r, id, Placed{p, id} <> acc)

def nth(ps: List<&2, Pt>, +k: U32, +dflt: Pt) -> Pt:
  Maybe.default(&2, Pt, List.get(&2, Pt, ps, U32.to_nat(k)), dflt)

def pt_head(ps: List<&2, Pt>, +dflt: Pt) -> Pt:
  Maybe.default(&2, Pt, List.head(&2, Pt, ps), dflt)

# ---- One street -------------------------------------------------------------

type Step is Data:
  Go{x: U32, z: U32, h: U32, turn: U32}
  Stop{through: Bool, edge: Bool}

# The next step of a street at (x, z) heading h, having run s. It wanders a
# few degrees a step; with a target it steers for it, harder as it nears.
def step_of(+bx: Box, +placed: List<&2, Placed>, +parent: U32, +from: Pt, +aim: Bool, +tg: Pt, +x: U32, +z: U32, +h: U32, +turn: U32, +s: U32, +r: U32) -> Step:
  +turn1 = U32.add(sdiv(U32.mul(turn, 4), 5), sdiv(U32.mul(U32.sub(r, 32768), 730), 65536))
  +h1 = U32.add(h, turn1)
  +here = {Pt{x, z} : Pt}
  +arrived = Bool.and(aim, within(here, tg, 900))
  +want = turn_from(atan2(U32.sub(pt_z(tg), z), U32.sub(pt_x(tg), x)), h1)
  +gain = Bool.pick(U32, U32.is_gt(s, 4000), 35, 10)
  +h2 = Bool.pick(U32, aim, U32.add(h1, clamp(sdiv(U32.mul(want, gain), 100), U32.sub(0, 1252), 1252)), h1)
  +nx = U32.add(x, sdiv(U32.mul(cos14(h2), step_cm()), 16384))
  +nz = U32.add(z, sdiv(U32.mul(sin14(h2), step_cm()), 16384))
  +out = Bool.and(Bool.not(inside(bx, nx, nz)), U32.is_gt(s, clear_cm()))
  Bool.pick(Step, arrived, Stop{True{}, False{}},
  Bool.pick(Step, out, Stop{False{}, True{}},
  Bool.pick(Step, hit(placed, Pt{nx, nz}, parent, from), Stop{False{}, False{}}, Go{nx, nz, h2, turn1})))

type Walked is Data:
  Walked{path: List<&2, Pt>, count: U32, n: U32, through: Bool, edge: Bool}

# A street's points, newest first.
def walk(fuel: Nat, step: Step, +bx: Box, +placed: List<&2, Placed>, +parent: U32, +from: Pt, +aim: Bool, +tg: Pt, +key: U32, +n: U32, +s: U32, +count: U32, +path: List<&2, Pt>) -> Walked:
  match fuel step:
    case 0n _:
      Walked{path, count, n, False{}, False{}}
    case 1n+p Stop{+through, edge}:
      Walked{Bool.pick(List<&2, Pt>, through, tg <> path, path), Bool.pick(U32, through, U32.add(count, 1), count), n, through, edge}
    case 1n+p Go{+x, +z, +h, +turn}:
      walk(p, step_of(bx, placed, parent, from, aim, tg, x, z, h, turn, U32.add(s, step_cm()), draw(key, n)),
        bx, placed, parent, from, aim, tg, key, U32.add(n, 1), U32.add(s, step_cm()), U32.add(count, 1), Pt{x, z} <> path)

# What the loop needs of the block, and what it builds.
type Ctx is Data:
  Ctx{seed: U32, d: U32, outer: Box, box: Box, cand: List<&2, Slot>, first: Slot, key: U32}

type St is Data:
  St{n: U32, next: U32, placed: List<&2, Placed>, joints: List<&2, Pt>, mouths: List<&2, Mouth>, streets: List<&2, Street>, linked: U32, bulb: U32, thru: U32}

type Task is Data:
  TThrough{xs: List<&2, Slot>}
  TTrunks{xs: List<&2, Slot>}
  TBranch{id: U32, path: List<&2, Pt>, len: U32, at: U32, side: Bool, depth: U32}
  TGrow{x: U32, z: U32, h: U32, depth: U32, parent: U32, from: Pt, tried: Bool}

type Grown is Data:
  Grown{st: St, stack: List<&2, Task>, ok: Bool}

type Run is Data:
  Run{st: St, stack: List<&2, Task>}

def ctx_outer(+c: Ctx) -> Box:
  match c:
    case Ctx{seed, d, outer, box, cand, first, key}:
      outer

def ctx_box(+c: Ctx) -> Box:
  match c:
    case Ctx{seed, d, outer, box, cand, first, key}:
      box

def ctx_key(+c: Ctx) -> U32:
  match c:
    case Ctx{seed, d, outer, box, cand, first, key}:
      key

def ctx_d(+c: Ctx) -> U32:
  match c:
    case Ctx{seed, d, outer, box, cand, first, key}:
      d

def ctx_cand(+c: Ctx) -> List<&2, Slot>:
  match c:
    case Ctx{seed, d, outer, box, cand, first, key}:
      cand

def ctx_first(+c: Ctx) -> Slot:
  match c:
    case Ctx{seed, d, outer, box, cand, first, key}:
      first

def st_n(+s: St) -> U32:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      n

def st_joints(+s: St) -> List<&2, Pt>:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      joints

def st_mouths(+s: St) -> List<&2, Mouth>:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      mouths

# Spend k rolls.
def st_bump(+s: St, +k: U32) -> St:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      St{U32.add(n, k), next, placed, joints, mouths, streets, linked, bulb, thru}

def st_joint(+s: St, +p: Pt) -> St:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      St{n, next, placed, p <> joints, mouths, streets, linked, bulb, thru}

def st_street(+s: St, +k: Street) -> St:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      St{n, next, placed, joints, mouths, k <> streets, linked, bulb, thru}

# An entrance opens: a straight street through the frontage, from the road to
# the box, and a junction where it reaches the box.
def open_into(+outer: Box, +bx: Box, +s: St, +m: Slot) -> St:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      +e = entry(outer, bx, m)
      St{n, next, placed, entry_end(e) <> joints, Mouth{slot_side(m), slot_t(m)} <> mouths,
        Street{2, False{}, [entry_start(e), entry_end(e)]} <> streets, linked, bulb, thru}

def open_slot(+c: Ctx, +s: St, +m: Slot) -> St:
  open_into(ctx_outer(c), ctx_box(c), s, m)

# How often a tip links on: a trunk nearly always, a branch more often than
# not, a twig half the time.
def link_odds(+depth: U32) -> U32:
  Bool.pick(U32, U32.is_eq(depth, 1), 62259, Bool.pick(U32, U32.is_eq(depth, 2), 45875, 32768))

# Street spacing reads the density at 256 levels.
def level(+d: U32) -> U32:
  U32.shrn(U32.min(d, 1023), 2n)

# Branches leave every 80 m in the fields to every 45 m in town.
def level_branch(+l: U32) -> U32:
  U32.sub(8000, U32.div(U32.mul(3500, l), 256))

def branch_every(+d: U32) -> U32:
  level_branch(level(d))

# Whether q lies ahead of the tip, coming from back: within 60 degrees, or
# anywhere ahead at the back of the shops.
def ahead(+back: Pt, +tip: Pt, +q: Pt, +edge: Bool) -> Bool:
  +ax = U32.sub(pt_x(tip), pt_x(back))
  +az = U32.sub(pt_z(tip), pt_z(back))
  +bx = U32.sub(pt_x(q), pt_x(tip))
  +bz = U32.sub(pt_z(q), pt_z(tip))
  +dot = U32.add(U32.mul(ax, bx), U32.mul(az, bz))
  Bool.pick(Bool, edge, slt(0, dot), slt(U32.mul(dist(tip, back), dist(tip, q)), U32.mul(dot, 2)))

def link_of(+near: Near, +back: Pt, +tip: Pt, +edge: Bool, +through: Bool, +joints: List<&2, Pt>, +placed: List<&2, Placed>, +r: U32, +depth: U32) -> Bool:
  match near:
    case Near{found, q, qid, d}:
      +mid = {Pt{U32.shrn(U32.add(pt_x(tip), pt_x(q)), 1n), U32.shrn(U32.add(pt_z(tip), pt_z(q)), 1n)} : Pt}
      Bool.and(Bool.and(Bool.and(Bool.not(through), found), Bool.and(U32.is_lt(d, Bool.pick(U32, edge, 8000, 6000)), ahead(back, tip, q, edge))),
        Bool.and(Bool.and(room_at(joints, q), U32.is_lt(r, link_odds(depth))),
          Bool.not(crossing(placed, mid, U32.sub(U32.max(U32.shrn(d, 1n), 200), 200), qid))))

def near_p(+near: Near) -> Pt:
  match near:
    case Near{found, q, qid, d}:
      q

# A street that ran far enough is kept: its tip links or ends in a turning
# circle, its points are placed, and its first branch point is queued.
def keep_street(ok: Bool, +c: Ctx, +s: St, +stack: List<&2, Task>, +w: Walked, +depth: U32, +parent: U32) -> Grown:
  match ok:
    case False{}:
      match s:
        case St{n0, next, placed, joints, mouths, streets, linked, bulb, thru}:
          match w:
            case Walked{path, count, n, through, edge}:
              Grown{St{n, next, placed, joints, mouths, streets, linked, bulb, thru}, stack, False{}}
    case True{}:
      match s:
        case St{n0, +id, +placed, +joints, mouths, streets, linked, bulb, thru}:
          match w:
            case Walked{+path, +cnt, +n, +through, +edge}:
              +tip = pt_head(path, Pt{0, 0})
              +back = nth(path, U32.min(3, U32.sub(cnt, 1)), tip)
              +near = nearest(placed, tip, parent, Near{False{}, tip, 0, 0})
              +link = link_of(near, back, tip, edge, through, joints, placed, draw(ctx_key(c), n), depth)
              +fwd = List.reverse(&2, Pt, path)
              +pts = Bool.pick(List<&2, Pt>, link, List.append(&2, Pt, fwd, [near_p(near)]), fwd)
              +len = U32.mul(U32.sub(cnt, 1), step_cm())
              +every = branch_every(ctx_d(c))
              +at = between(U32.div(U32.mul(every, 3), 5), every, draw(ctx_key(c), U32.add(n, 2)))
              +side = U32.is_lt(draw(ctx_key(c), U32.add(n, 1)), 32768)
              +bulb_end = Bool.and(Bool.not(through), Bool.not(link))
              Grown{St{U32.add(n, 3), U32.add(id, 1), place_all(path, id, placed),
                  Bool.pick(List<&2, Pt>, link, near_p(near) <> joints, joints), mouths,
                  Street{0, bulb_end, pts} <> streets,
                  U32.add(linked, count(link)), U32.add(bulb, count(bulb_end)), U32.add(thru, count(through))},
                Bool.pick(List<&2, Task>, U32.is_lt(depth, 3), TBranch{id, fwd, len, at, side, depth} <> stack, stack),
                True{}}

def walked_ok(+w: Walked, +aim: Bool) -> Bool:
  match w:
    case Walked{path, count, n, through, edge}:
      Bool.and(U32.is_ge(U32.mul(U32.sub(count, 1), step_cm()), 3000), Bool.or(Bool.not(aim), through))

def grow_walked(+c: Ctx, +s: St, +stack: List<&2, Task>, +w: Walked, +aim: Bool, +depth: U32, +parent: U32) -> Grown:
  keep_street(walked_ok(w, aim), c, s, stack, w, depth, parent)

# Grow one street from (x, z) heading h, at most `most` long. With `aim`, it
# steers for tg and is kept only if it gets there.
def grow_street(+c: Ctx, +s: St, +stack: List<&2, Task>, +x: U32, +z: U32, +h: U32, +most: U32, +depth: U32, +parent: U32, +from: Pt, +aim: Bool, +tg: Pt) -> Grown:
  match s:
    case St{+n, next, +placed, joints, mouths, streets, linked, bulb, thru}:
      +fuel = U32.to_nat(U32.add(U32.div(U32.add(most, 599), step_cm()), 1))
      +first = step_of(ctx_box(c), placed, parent, from, aim, tg, x, z, h, 0, 0, draw(ctx_key(c), n))
      grow_walked(c, s, stack, walk(fuel, first, ctx_box(c), placed, parent, from, aim, tg, ctx_key(c), U32.add(n, 1), 0, 1, [Pt{x, z}]), aim, depth, parent)

# ---- The loop -----------------------------------------------------------------

def empty_st() -> St:
  St{0, 0, [], [], [], [], 0, 0, 0}

def slot_head(xs: List<&2, Slot>) -> Slot:
  Maybe.default(&2, Slot, List.head(&2, Slot, xs), Slot{0, 0, 0, 0, 0, 0})

def on_side(xs: List<&2, Slot>, +side: U32) -> List<&2, Slot>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+s, r}:
      +rest = on_side(r, side)
      Bool.pick(List<&2, Slot>, U32.is_eq(slot_side(s), side), s <> rest, rest)

def off_sides(xs: List<&2, Slot>, +a: U32, +b: U32) -> List<&2, Slot>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+s, r}:
      +rest = off_sides(r, a, b)
      Bool.pick(List<&2, Slot>, Bool.or(U32.is_eq(slot_side(s), a), U32.is_eq(slot_side(s), b)), rest, s <> rest)

# Where the first trunk may run through to: an entrance on the opposite road
# first, then the others, most wanted first; three tries.
def exits_of(+cand: List<&2, Slot>, +first: Slot) -> List<&2, Slot>:
  +f = slot_side(first)
  +o = U32.xor(f, 1)
  List.take(&2, Slot, List.append(&2, Slot, on_side(cand, o), off_sides(cand, f, o)), 3n)

# An entrance no street uses yet, within 260 m and 50 degrees of a heading,
# with room for a junction where it meets the box; the nearest.
def free_ahead(xs: List<&2, Slot>, +c: Ctx, +ms: List<&2, Mouth>, +js: List<&2, Pt>, +q: Pt, +h: U32, +best: Maybe<&2, Slot>, +bd: U32) -> Maybe<&2, Slot>:
  match xs:
    case Nil{}:
      best
    case Con{+s, r}:
      +e = entry_end(entry(ctx_outer(c), ctx_box(c), s))
      +dd = dist(q, e)
      +off = sabs(turn_from(atan2(U32.sub(pt_z(e), pt_z(q)), U32.sub(pt_x(e), pt_x(q))), h))
      +ok = Bool.and(Bool.and(Bool.not(has_mouth(ms, slot_side(s), slot_t(s))), U32.is_lt(dd, bd)),
            Bool.and(U32.is_lt(off, 9074), room_at(js, e)))
      free_ahead(r, c, ms, js, q, h, Bool.pick(Maybe<&2, Slot>, ok, Some{s}, best), Bool.pick(U32, ok, dd, bd))

def grown_run(g: Grown) -> Run:
  match g:
    case Grown{st, stack, ok}:
      Run{st, stack}

# A street that reached its target opens the entrances at both its ends;
# one that did not leaves the next try on the stack.
def through_done(g: Grown, +c: Ctx, +x: Slot, +retry: Task) -> Run:
  match g:
    case Grown{st, stack, ok}:
      match ok:
        case True{}:
          Run{open_slot(c, open_slot(c, st, ctx_first(c)), x), stack}
        case False{}:
          Run{st, retry <> stack}

def through_task(xs: List<&2, Slot>, +c: Ctx, +st: St, +rest: List<&2, Task>) -> Run:
  match xs:
    case Nil{}:
      Run{st, rest}
    case Con{+x, more}:
      +a = entry(ctx_outer(c), ctx_box(c), ctx_first(c))
      +b = entry(ctx_outer(c), ctx_box(c), x)
      +sp = entry_end(a)
      through_done(grow_street(c, st, rest, pt_x(sp), pt_z(sp), entry_h(a), 120000, 1, none_id(), sp, True{}, entry_end(b)), c, x, TThrough{more})

def opened(g: Grown, +c: Ctx, +m: Slot) -> Run:
  match g:
    case Grown{+st, stack, +ok}:
      Run{Bool.pick(St, ok, open_slot(c, st, m), st), stack}

# Every other entrance grows a trunk 260 to 480 m long, within 17 degrees of
# straight in.
def trunk_go(done: Bool, +c: Ctx, +st: St, +m: Slot, +next: List<&2, Task>) -> Run:
  match done:
    case True{}:
      Run{st, next}
    case False{}:
      +e = entry(ctx_outer(c), ctx_box(c), m)
      +sp = entry_end(e)
      +n = st_n(st)
      +h = U32.add(entry_h(e), U32.sub(between(0, 6258, draw(ctx_key(c), n)), 3129))
      +most = between(26000, 48000, draw(ctx_key(c), U32.add(n, 1)))
      opened(grow_street(c, st_bump(st, 2), next, pt_x(sp), pt_z(sp), h, most, 1, none_id(), sp, False{}, sp), c, m)

def trunks_task(xs: List<&2, Slot>, +c: Ctx, +st: St, +rest: List<&2, Task>) -> Run:
  match xs:
    case Nil{}:
      Run{st, rest}
    case Con{+m, more}:
      +next = {TTrunks{more} <> rest : List<&2, Task>}
      trunk_go(has_mouth(st_mouths(st), slot_side(m), slot_t(m)), c, st, m, next)

# The next branch point along a street. Branches leave at 60 to 100 degrees,
# on alternating sides, now and then both sides at once: a crossing. Twigs
# are fewer than branches.
def branch_go(go: Bool, +c: Ctx, +st: St, +id: U32, +path: List<&2, Pt>, +len: U32, +at: U32, +side: Bool, +depth: U32, +rest: List<&2, Task>) -> Run:
  match go:
    case False{}:
      Run{st, rest}
    case True{}:
      +key = ctx_key(c)
      +k = U32.div(U32.add(at, 300), step_cm())
      +q = nth(path, k, Pt{0, 0})
      +q1 = nth(path, U32.add(k, 1), q)
      +hh = atan2(U32.sub(pt_z(q1), pt_z(q)), U32.sub(pt_x(q1), pt_x(q)))
      +n = st_n(st)
      +every = branch_every(ctx_d(c))
      +at2 = U32.add(at, between(U32.div(U32.mul(every, 4), 5), U32.div(U32.mul(every, 6), 5), draw(key, n)))
      +same = {TBranch{id, path, len, at2, side, depth} <> rest : List<&2, Task>}
      +flip = {TBranch{id, path, len, at2, Bool.not(side), depth} <> rest : List<&2, Task>}
      +skip = Bool.and(U32.is_eq(depth, 2), U32.is_lt(draw(key, U32.add(n, 1)), 39322))
      +both = U32.is_lt(draw(key, U32.add(n, 2)), 9830)
      +w1 = between(10948, 18254, draw(key, U32.add(n, 3)))
      +w2 = between(10948, 18254, draw(key, U32.add(n, 4)))
      +g1 = {TGrow{pt_x(q), pt_z(q), Bool.pick(U32, side, U32.add(hh, w1), U32.sub(hh, w1)), U32.add(depth, 1), id, q, False{}} : Task}
      +g2 = {TGrow{pt_x(q), pt_z(q), Bool.pick(U32, side, U32.sub(hh, w2), U32.add(hh, w2)), U32.add(depth, 1), id, q, False{}} : Task}
      +grow = Bool.pick(List<&2, Task>, both, g1 <> g2 <> flip, g1 <> flip)
      Bool.pick(Run, Bool.not(room_at(st_joints(st), q)), Run{st_bump(st, 1), same},
        Bool.pick(Run, skip, Run{st_bump(st_joint(st, q), 2), flip}, Run{st_bump(st_joint(st, q), 5), grow}))

def branch_task(+c: Ctx, +st: St, +id: U32, +path: List<&2, Pt>, +len: U32, +at: U32, +side: Bool, +depth: U32, +rest: List<&2, Task>) -> Run:
  branch_go(U32.is_lt(U32.add(at, lok_floor_cm()), len), c, st, id, path, len, at, side, depth, rest)

# A branch or twig, 150 to 320 m over the square root of its depth.
def plain_grow(+c: Ctx, +st: St, +x: U32, +z: U32, +h: U32, +depth: U32, +parent: U32, +from: Pt, +rest: List<&2, Task>) -> Run:
  +most = U32.div(U32.mul(between(15000, 32000, draw(ctx_key(c), st_n(st))), 1000), Bool.pick(U32, U32.is_eq(depth, 2), 1414, 1732))
  grown_run(grow_street(c, st_bump(st, 1), rest, x, z, h, most, depth, parent, from, False{}, from))

def aimed(g: Grown, +c: Ctx, +s: Slot, +retry: Task) -> Run:
  match g:
    case Grown{st, stack, ok}:
      match ok:
        case True{}:
          Run{open_slot(c, st, s), stack}
        case False{}:
          Run{st, retry <> stack}

# A branch that points at a free entrance on a big road steers for it, and
# becomes another way out of the block.
def aim_with(m: Maybe<&2, Slot>, +c: Ctx, +st: St, +x: U32, +z: U32, +h: U32, +depth: U32, +parent: U32, +from: Pt, +rest: List<&2, Task>) -> Run:
  match m:
    case None{}:
      plain_grow(c, st, x, z, h, depth, parent, from, rest)
    case Some{+s}:
      +b = entry_end(entry(ctx_outer(c), ctx_box(c), s))
      aimed(grow_street(c, st, rest, x, z, h, 60000, depth, parent, from, True{}, b), c, s, TGrow{x, z, h, depth, parent, from, True{}})

def aim_go(go: Bool, +c: Ctx, +st: St, +x: U32, +z: U32, +h: U32, +depth: U32, +parent: U32, +from: Pt, +rest: List<&2, Task>) -> Run:
  match go:
    case True{}:
      aim_with(free_ahead(ctx_cand(c), c, st_mouths(st), st_joints(st), Pt{x, z}, h, None{}, 26000), c, st, x, z, h, depth, parent, from, rest)
    case False{}:
      plain_grow(c, st, x, z, h, depth, parent, from, rest)

def do_task(t: Task, +c: Ctx, +st: St, +rest: List<&2, Task>) -> Run:
  match t:
    case TThrough{xs}:
      through_task(xs, c, st, rest)
    case TTrunks{xs}:
      trunks_task(xs, c, st, rest)
    case TBranch{id, path, len, at, side, depth}:
      branch_task(c, st, id, path, len, at, side, depth, rest)
    case TGrow{x, z, h, +depth, parent, from, tried}:
      aim_go(Bool.and(U32.is_eq(depth, 2), Bool.not(tried)), c, st, x, z, h, depth, parent, from, rest)

def run_st(r: Run) -> St:
  match r:
    case Run{st, stack}:
      st

def run(fuel: Nat, +c: Ctx, r: Run) -> St:
  match fuel:
    case 0n:
      run_st(r)
    case 1n+p:
      match r:
        case Run{st, stack}:
          match stack:
            case Nil{}:
              st
            case Con{t, rest}:
              run(p, c, do_task(t, c, st, rest))

# The first entrance's trunk tries to run through; then every entrance not
# yet open grows its own trunk.
def grow_tree(+c: Ctx, +st: St, +used: List<&2, Slot>) -> St:
  run(4000n, c, Run{st, [TThrough{exits_of(ctx_cand(c), ctx_first(c))}, TTrunks{used}]})

# ---- Lanes, combs and grids ---------------------------------------------------

def st_streets(+s: St, +xs: List<&2, Street>) -> St:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      St{n, next, placed, joints, mouths, List.append(&2, Street, xs, streets), linked, bulb, thru}

def lane_street(+b: Box) -> Street:
  match b:
    case Box{+x0, +x1, +z0, +z1}:
      Street{1, False{}, [Pt{x0, z0}, Pt{x1, z0}, Pt{x1, z1}, Pt{x0, z1}, Pt{x0, z0}]}

def open_all(xs: List<&2, Slot>, +outer: Box, +bx: Box, +st: St) -> St:
  match xs:
    case Nil{}:
      st
    case Con{+m, r}:
      open_all(r, outer, bx, open_into(outer, bx, st, m))

# A lane round a box, and a mouth from each entrance to it.
def lane(+outer: Box, +bx: Box, +entries: List<&2, Slot>, +st: St) -> St:
  open_all(entries, outer, bx, st_street(st, lane_street(bx)))

def bool_eq(+a: Bool, +b: Bool) -> Bool:
  Bool.not(Bool.xor(a, b))

# Whether a cross street at a..b would meet the lane within 30 m of a mouth.
def near_mouth(xs: List<&2, Slot>, +u: Bool, +a: U32, +b: U32) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+s, r}:
      +at = slot_at(s)
      Bool.or(Bool.and(bool_eq(along_u(slot_side(s)), u), U32.is_lt(U32.min(sabs(U32.sub(at, a)), sabs(U32.sub(at, b))), 3000)),
        near_mouth(r, u, a, b))

# Streets across a lane, one every `gap` or so: across u (at a fixed x), or
# across v. A street leans by `lean`, its far end that much further on; it
# keeps the lokal floor from the lane's corners and 30 m from every mouth.
def across_go(fuel: Nat, +k: U32, +n: U32, +u: Bool, +lo: U32, +hi: U32, +o0: U32, +o1: U32, +lean: U32, +ms: List<&2, Slot>, +acc: List<&2, Street>) -> List<&2, Street>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +t = U32.add(lo, U32.div(U32.mul(U32.sub(hi, lo), k), n))
      +a = U32.sub(t, sdiv(lean, 2))
      +b = U32.add(t, sdiv(lean, 2))
      +ok = Bool.and(Bool.and(U32.is_lt(k, n), Bool.not(slt(smin(a, b), U32.add(lo, lok_floor_cm())))),
            Bool.and(Bool.not(slt(U32.sub(hi, lok_floor_cm()), smax(a, b))), Bool.not(near_mouth(ms, u, a, b))))
      +pts = Bool.pick(List<&2, Pt>, u, [Pt{a, o0}, Pt{b, o1}], [Pt{o0, a}, Pt{o1, b}])
      across_go(p, U32.add(k, 1), n, u, lo, hi, o0, o1, lean, ms, Bool.pick(List<&2, Street>, ok, Street{3, False{}, pts} <> acc, acc))

def across(+u: Bool, +lo: U32, +hi: U32, +o0: U32, +o1: U32, +gap: U32, +lean: U32, +ms: List<&2, Slot>) -> List<&2, Street>:
  +n = U32.max(U32.div(U32.sub(hi, lo), gap), 1)
  across_go(U32.to_nat(n), 1, n, u, lo, hi, o0, o1, lean, ms, Nil{})

# Between streets 85 m in the fields, 55 m in town.
def level_gap(+l: U32) -> U32:
  U32.sub(8500, U32.div(U32.mul(3000, l), 256))

def cross_gap(+d: U32) -> U32:
  level_gap(level(d))

# A comb's teeth lean up to 25 degrees, so the estate is not square to its
# frame.
def comb(+bx: Box, +d: U32, +r: U32, +ms: List<&2, Slot>) -> List<&2, Street>:
  +long_u = Bool.not(slt(box_w(bx), box_h(bx)))
  +span = Bool.pick(U32, long_u, box_h(bx), box_w(bx))
  +a = sdiv(U32.mul(U32.sub(U32.mul(r, 2), 1024), 4589), 1024)
  +s = sin14(a)
  +lean = signed(is_neg(s), U32.div(U32.mul(sabs(s), span), cos14(a)))
  Bool.pick(List<&2, Street>, long_u,
    across(True{}, box_x0(bx), box_x1(bx), box_z0(bx), box_z1(bx), cross_gap(d), lean, ms),
    across(False{}, box_z0(bx), box_z1(bx), box_x0(bx), box_x1(bx), cross_gap(d), lean, ms))

def grid(+bx: Box, +d: U32, +ms: List<&2, Slot>) -> List<&2, Street>:
  +g = cross_gap(d)
  List.append(&2, Street,
    across(True{}, box_x0(bx), box_x1(bx), box_z0(bx), box_z1(bx), U32.div(U32.mul(g, 6), 5), 0, ms),
    across(False{}, box_z0(bx), box_z1(bx), box_x0(bx), box_x1(bx), U32.div(U32.mul(g, 7), 5), 0, ms))

# ---- Rings ----------------------------------------------------------------------

# A ring is as big as its court and a row of houses round it: alun-alun,
# pasar, sekolah, gudang; the long side, else the short one.
def ring_size(+court: U32, +long: Bool) -> U32:
  Bool.pick(U32, U32.is_eq(court, 0), Bool.pick(U32, long, 15000, 12500),
  Bool.pick(U32, U32.is_eq(court, 1), Bool.pick(U32, long, 11000, 9000),
  Bool.pick(U32, U32.is_eq(court, 2), Bool.pick(U32, long, 12000, 9000), Bool.pick(U32, long, 12000, 9500))))

# What is left beside a ring must be this wide to grow streets of its own.
def ring_rest_cm() -> U32:
  10000

# The ring facing an entrance: centred on it along the road, the long side
# along the road; where what is left is too thin for streets, the ring takes
# it too.
def ring_box(+m: Slot, +inner: Box, +court: U32) -> Box:
  match inner:
    case Box{+x0, +x1, +z0, +z1}:
      +side = slot_side(m)
      +at = slot_at(m)
      +across = along_u(side)
      +au = ring_size(court, across)
      +av = ring_size(court, Bool.not(across))
      +cu = Bool.pick(U32, across, clamp(U32.sub(at, U32.shrn(au, 1n)), x0, U32.sub(x1, au)),
              Bool.pick(U32, U32.is_eq(side, 2), x0, U32.sub(x1, au)))
      +cv = Bool.pick(U32, across, Bool.pick(U32, U32.is_eq(side, 0), z0, U32.sub(z1, av)),
              clamp(U32.sub(at, U32.shrn(av, 1n)), z0, U32.sub(z1, av)))
      +a0 = smax(x0, cu)
      +a1 = smin(x1, U32.add(cu, au))
      +b0 = smax(z0, cv)
      +b1 = smin(z1, U32.add(cv, av))
      +rest = ring_rest_cm()
      Box{Bool.pick(U32, slt(U32.sub(a0, x0), rest), x0, a0), Bool.pick(U32, slt(U32.sub(x1, a1), rest), x1, a1),
          Bool.pick(U32, slt(U32.sub(b0, z0), rest), z0, b0), Bool.pick(U32, slt(U32.sub(z1, b1), rest), z1, b1)}

type Placing is Data:
  Placing{found: Bool, ring: Box, entries: List<&2, Slot>}

def placing_found(+p: Placing) -> Bool:
  match p:
    case Placing{found, ring, entries}:
      found

# The ring at the first entrance, most wanted first, that leaves it an
# entrance of its own.
def place_ring(xs: List<&2, Slot>, +seed: U32, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge, +inner: Box, +court: U32, +mu: U32, +mv: U32, +best: Placing) -> Placing:
  match xs:
    case Nil{}:
      best
    case Con{+m, r}:
      +bx = ring_box(m, inner, court)
      +e = entrances(seed, es, en, ew, ee, bx, inner, mu, mv)
      +take = Bool.and(Bool.not(placing_found(best)), Bool.not(List.is_empty(&2, Slot, e)))
      place_ring(r, seed, es, en, ew, ee, inner, court, mu, mv, Bool.pick(Placing, take, Placing{True{}, bx, pick_used(e)}, best))

# Between a ring's lane and the streets beside it: two rows of lots.
def ring_gap_cm() -> U32:
  2600

# What is left beside a ring: a strip along its open sides in u, then along
# its open sides in v, between them.
def rests_of(+ring: Box, +inner: Box) -> List<&2, Box>:
  match ring:
    case Box{+a0, +a1, +b0, +b1}:
      match inner:
        case Box{+x0, +x1, +z0, +z1}:
          +g = ring_gap_cm()
          +s = Bool.pick(List<&2, Box>, slt(z0, b0), [Box{a0, a1, z0, U32.sub(b0, g)}], [])
          +n = Bool.pick(List<&2, Box>, slt(b1, z1), Box{a0, a1, U32.add(b1, g), z1} <> s, s)
          +w = Bool.pick(List<&2, Box>, slt(x0, a0), Box{x0, U32.sub(a0, g), z0, z1} <> n, n)
          Bool.pick(List<&2, Box>, slt(a1, x1), Box{U32.add(a1, g), x1, z0, z1} <> w, w)

def rest_go(go: Bool, +c: Ctx, +used: List<&2, Slot>, +st: St) -> St:
  match go:
    case True{}:
      grow_tree(c, st, used)
    case False{}:
      st

# Each strip wide enough, with an entrance, grows its own tree.
def grow_rests(rs: List<&2, Box>, +k: U32, +seed: U32, +i: U32, +j: U32, +u0: U32, +v0: U32, +d: U32, +outer: Box, +inner: Box, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge, +mu: U32, +mv: U32, +st: St) -> St:
  match rs:
    case Nil{}:
      st
    case Con{+rb, r}:
      +e = entrances(seed, es, en, ew, ee, rb, inner, mu, mv)
      +used = pick_used(e)
      +c = {Ctx{seed, d, outer, rb, e, slot_head(used), hash6(seed, 20, i, j, u0, v0, U32.add(k, 1))} : Ctx}
      grow_rests(r, U32.add(k, 1), seed, i, j, u0, v0, d, outer, inner, es, en, ew, ee, mu, mv,
        rest_go(Bool.and(roomy(rb, 7000), Bool.not(List.is_empty(&2, Slot, e))), c, used, st))

# ---- A block --------------------------------------------------------------------

# What a block became (0 sawah, 1 kebun, 2 tree, 3 comb, 4 grid, 5 ring,
# 6 shops), its court (4 for none) and ring lane, its streets and the
# entrances they use, and how its tree streets end.
type Fill is Data:
  Fill{land: U32, court: U32, ring: Box, streets: List<&2, Street>, mouths: List<&2, Mouth>, linked: U32, bulb: U32, thru: U32}

def fill_of(+land: U32, +court: U32, +ring: Box, +s: St) -> Fill:
  match s:
    case St{n, next, placed, joints, mouths, streets, linked, bulb, thru}:
      Fill{land, court, ring, streets, mouths, linked, bulb, thru}

def zero_box() -> Box:
  Box{0, 0, 0, 0}

def placing_fill(p: Placing, +court: U32, +seed: U32, +i: U32, +j: U32, +u0: U32, +v0: U32, +d: U32, +outer: Box, +inner: Box, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge, +mu: U32, +mv: U32) -> Fill:
  match p:
    case Placing{found, +ring, +entries}:
      fill_of(5, court, ring, grow_rests(rests_of(ring, inner), 0, seed, i, j, u0, v0, d, outer, inner, es, en, ew, ee, mu, mv,
        lane(outer, ring, entries, empty_st())))

def land_fill(l: Land, +c: Ctx, +seed: U32, +i: U32, +j: U32, +u0: U32, +v0: U32, +d: U32, +r: U32, +outer: Box, +bx: Box, +cand: List<&2, Slot>, +used: List<&2, Slot>, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge, +mu: U32, +mv: U32) -> Fill:
  match l:
    case Tree{}:
      fill_of(2, 4, zero_box(), grow_tree(c, empty_st(), used))
    case Comb{}:
      fill_of(3, 4, zero_box(), st_streets(lane(outer, bx, used, empty_st()), comb(bx, d, r, used)))
    case Grid{}:
      fill_of(4, 4, zero_box(), st_streets(lane(outer, bx, used, empty_st()), grid(bx, d, used)))
    case Ring{}:
      +court = court(d, roll(hash5(seed, 14, i, j, u0, v0)))
      placing_fill(place_ring(cand, seed, es, en, ew, ee, bx, court, mu, mv, Placing{False{}, bx, used}),
        court, seed, i, j, u0, v0, d, outer, bx, es, en, ew, ee, mu, mv)
    case _:
      fill_of(6, 4, zero_box(), empty_st())

def built_fill(go: Bool, +l: U32, +seed: U32, +i: U32, +j: U32, +u0: U32, +v0: U32, +d: U32, +r: U32, +outer: Box, +bx: Box, +cand: List<&2, Slot>, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge, +mu: U32, +mv: U32) -> Fill:
  match go:
    case False{}:
      fill_of(Bool.pick(U32, U32.is_lt(l, 2), l, 6), 4, zero_box(), empty_st())
    case True{}:
      +used = pick_used(cand)
      +c = {Ctx{seed, d, outer, bx, cand, slot_head(used), hash6(seed, 20, i, j, u0, v0, 0)} : Ctx}
      land_fill(land_of(d, r), c, seed, i, j, u0, v0, d, r, outer, bx, cand, used, es, en, ew, ee, mu, mv)

# The frontage row on a main road is 35 m deep; a side with no road keeps 12 m.
def inset(+e: Edge) -> U32:
  Bool.pick(U32, edge_road(e), 3500, 1200)

# Fill the block (u0..u1, v0..v1 in 65536ths) of cell (i, j), with the road,
# or none, on each side of it. Sawah and kebun stay open; a block too small
# for streets, or with no entrance, is shops along its roads.
def block_fill(+seed: U32, +i: U32, +j: U32, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge) -> Fill:
  +f = frame_of(seed, i, j)
  +mu = frame_mu(f)
  +mv = frame_mv(f)
  +outer = {Box{mul16(mu, u0), mul16(mu, u1), mul16(mv, v0), mul16(mv, v1)} : Box}
  +mid = frame_at(f, U32.shrn(U32.add(u0, u1), 1n), U32.shrn(U32.add(v0, v1), 1n))
  +d = density(seed, pt_x(mid), pt_z(mid))
  +r = roll(hash5(seed, 11, i, j, u0, v0))
  +l = land(d, r)
  +bx = {Box{U32.add(box_x0(outer), inset(ew)), U32.sub(box_x1(outer), inset(ee)), U32.add(box_z0(outer), inset(es)), U32.sub(box_z1(outer), inset(en))} : Box}
  +cand = entrances(seed, es, en, ew, ee, bx, bx, mu, mv)
  built_fill(Bool.and(Bool.and(Bool.not(U32.is_lt(l, 2)), roomy(bx, 7000)), Bool.not(List.is_empty(&2, Slot, cand))),
    l, seed, i, j, u0, v0, d, r, outer, bx, cand, es, en, ew, ee, mu, mv)

# ---- For the laws: the spacing the density sets ---------------------------------

# Whether ok holds at every level of density, 0 to 255. Spacing reads density
# only through `level`, so this is every density.
def levels_from(~ok: U32 -> Bool, fuel: Nat, +l: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      Bool.and(ok(l), levels_from(~ok, p, U32.add(l, 1)))

# Streets across a lane stand at least `cross_gap` apart, since a lane of
# length L holds floor(L / gap) of them; the grid's are wider still. That
# leaves two rows of lots, back to back, between two streets.
def every_cross_gap_holds_lots() -> Bool:
  levels_from(~(l => U32.is_ge(level_gap(l), U32.mul(clear_cm(), 2))), 256n, 0)

# Branch points along a street stand at least four fifths of `branch_every`
# apart: never nearer than the lokal floor.
def every_branch_gap_keeps_floor() -> Bool:
  levels_from(~(l => U32.is_ge(U32.div(U32.mul(level_branch(l), 4), 5), lok_floor_cm())), 256n, 0)

# ===========================================================================
# A whole cell: its roads, its blocks and the streets in them, on the ground
#
# The cell owns its south and west lattice roads, so every road of the world
# belongs to exactly one cell. Points are world centimetres; a block's
# corners are in 65536ths of the frame.
# ===========================================================================

# 0 the lattice road east from the corner, 9 the one south, 1 a collector
# across u, 2 one across v, 3 the river, 4 a tree street, 5 one ending in a
# turning circle, 6 a ring lane, 7 a mouth, 8 a cross street.
type Line is Data:
  Line{kind: U32, tag: U32, pts: List<&2, Pt>}

type Blk is Data:
  Blk{u0: U32, u1: U32, v0: U32, v1: U32, d: U32, s_road: Bool, n_road: Bool, w_road: Bool, e_road: Bool, fill: Fill}

type Cell is Data:
  Cell{f: Frame, lines: List<&2, Line>, blocks: List<&2, Blk>}

# n + 1 points along a curve, or along a line of the frame at a fixed u (or v).
def curve_pts(fuel: Nat, +k: Curve, +n: U32, +s: U32, acc: List<&2, Pt>) -> List<&2, Pt>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      curve_pts(p, k, n, U32.sub(s, 1), curve_at(k, U32.div(U32.mul(s, 65536), n)) <> acc)

def road_pts(+seed: U32, +i: U32, +j: U32, +east: Bool) -> List<&2, Pt>:
  curve_pts(65n, curve_of(seed, i, j, east), 64, 64, Nil{})

def frame_pts(fuel: Nat, +f: Frame, +fixed_u: Bool, +at: U32, +s: U32, acc: List<&2, Pt>) -> List<&2, Pt>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +t = U32.mul(s, 1024)
      frame_pts(p, f, fixed_u, at, U32.sub(s, 1), frame_at(f, Bool.pick(U32, fixed_u, at, t), Bool.pick(U32, fixed_u, t, at)) <> acc)

def river_pts(fuel: Nat, +seed: U32, +i: U32, +j: U32, +f: Frame, +s: U32, acc: List<&2, Pt>) -> List<&2, Pt>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +u = U32.div(U32.mul(s, 65536), 24)
      river_pts(p, seed, i, j, f, U32.sub(s, 1), frame_at(f, u, river_v(seed, i, j, u)) <> acc)

# x / m in 65536ths, exactly, for x below 2^23.
def frac16(+x: U32, +m: U32) -> U32:
  +mm = U32.max(m, 1)
  +hi = U32.div(U32.mul(x, 256), mm)
  +r = U32.sub(U32.mul(x, 256), U32.mul(hi, mm))
  U32.add(U32.mul(hi, 256), U32.div(U32.mul(r, 256), mm))

# A street of the block's metric frame, on the ground: each straight run of
# it drawn every 10 m or so through the frame, so it bends with the frame.
def run_pts(fuel: Nat, +f: Frame, +a: Pt, +b: Pt, +n: U32, +k: U32, acc: List<&2, Pt>) -> List<&2, Pt>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +q = pt_lerp(a, b, U32.div(U32.mul(k, 65536), n))
      run_pts(p, f, a, b, n, U32.add(k, 1), frame_at(f, frac16(pt_x(q), frame_mu(f)), frac16(pt_z(q), frame_mv(f))) <> acc)

def street_go(ps: List<&2, Pt>, +f: Frame, +prev: Pt, acc: List<&2, Pt>) -> List<&2, Pt>:
  match ps:
    case Nil{}:
      acc
    case Con{+q, r}:
      +n = U32.max(1, U32.div(U32.add(dist(prev, q), 995), 1000))
      street_go(r, f, q, run_pts(U32.to_nat(n), f, prev, q, n, 1, acc))

def street_world(ps: List<&2, Pt>, +f: Frame) -> List<&2, Pt>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+q, r}:
      List.reverse(&2, Pt, street_go(r, f, q, [frame_at(f, frac16(pt_x(q), frame_mu(f)), frac16(pt_z(q), frame_mv(f)))]))

def street_tag(+s: Street) -> U32:
  match s:
    case Street{tag, bulb, pts}:
      Bool.pick(U32, U32.is_eq(tag, 0), Bool.pick(U32, bulb, 5, 4), U32.add(tag, 5))

def street_lines(ss: List<&2, Street>, +f: Frame, acc: List<&2, Line>) -> List<&2, Line>:
  match ss:
    case Nil{}:
      acc
    case Con{+s, r}:
      match s:
        case Street{tag, bulb, pts}:
          street_lines(r, f, Line{3, street_tag(s), street_world(pts, f)} <> acc)

def fill_streets(+x: Fill) -> List<&2, Street>:
  match x:
    case Fill{land, court, ring, streets, mouths, linked, bulb, thru}:
      streets

def blk_lines(bs: List<&2, Blk>, +f: Frame, acc: List<&2, Line>) -> List<&2, Line>:
  match bs:
    case Nil{}:
      acc
    case Con{+b, r}:
      match b:
        case Blk{u0, u1, v0, v1, d, sr, nr, wr, er, fill}:
          blk_lines(r, f, street_lines(fill_streets(fill), f, acc))

# The road along a lattice side of the cell, with the collectors' mouths on
# it from either side.
def side_edge(+seed: U32, +i: U32, +j: U32, +east: Bool) -> Edge:
  Edge{has_road(seed, i, j, east), i, j, Bool.pick(U32, east, 0, 1), road_length(seed, i, j, east),
    side_mouth(seed, i, j, east, 0), side_mouth(seed, i, j, east, 1), 0, 65536}

def far() -> U32:
  4294967295

def no_edge() -> Edge:
  Edge{False{}, 0, 0, 0, 0, far(), far(), 0, 0}

def edge_span(+e: Edge, +t0: U32, +t1: U32) -> Edge:
  match e:
    case Edge{road, k0, k1, k2, len, a0, a1, a, b}:
      Edge{road, k0, k1, k2, len, a0, a1, t0, t1}

def make_blk(+seed: U32, +i: U32, +j: U32, +f: Frame, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge) -> Blk:
  +mid = frame_at(f, U32.shrn(U32.add(u0, u1), 1n), U32.shrn(U32.add(v0, v1), 1n))
  Blk{u0, u1, v0, v1, density(seed, pt_x(mid), pt_z(mid)), edge_road(es), edge_road(en), edge_road(ew), edge_road(ee),
    block_fill(seed, i, j, u0, u1, v0, v1, es, en, ew, ee)}

# The water's v-range over u0..u1, from 17 samples.
def water_lo(fuel: Nat, +seed: U32, +i: U32, +j: U32, +u0: U32, +u1: U32, +k: U32, +lo: U32) -> U32:
  match fuel:
    case 0n:
      lo
    case 1n+p:
      water_lo(p, seed, i, j, u0, u1, U32.add(k, 1), U32.min(lo, river_v(seed, i, j, lerp(u0, u1, U32.mul(k, 4096)))))

def water_hi(fuel: Nat, +seed: U32, +i: U32, +j: U32, +u0: U32, +u1: U32, +k: U32, +hi: U32) -> U32:
  match fuel:
    case 0n:
      hi
    case 1n+p:
      water_hi(p, seed, i, j, u0, u1, U32.add(k, 1), U32.max(hi, river_v(seed, i, j, lerp(u0, u1, U32.mul(k, 4096)))))

# A river cell is split by the water, which leaves a green bank of 15 m each
# side of it.
def blocks_of(river: Bool, +seed: U32, +i: U32, +j: U32, +f: Frame, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +es: Edge, +en: Edge, +ew: Edge, +ee: Edge) -> List<&2, Blk>:
  match river:
    case False{}:
      [make_blk(seed, i, j, f, u0, u1, v0, v1, es, en, ew, ee)]
    case True{}:
      +bank = frac16(U32.add(river_half_cm(), 1500), frame_mv(f))
      +lo = U32.sub(water_lo(17n, seed, i, j, u0, u1, 0, 65536), bank)
      +hi = U32.add(water_hi(17n, seed, i, j, u0, u1, 0, 0), bank)
      [make_blk(seed, i, j, f, u0, u1, v0, lo, es, no_edge(), ew, ee), make_blk(seed, i, j, f, u0, u1, hi, v1, no_edge(), en, ew, ee)]

# The cuts at 0 and 65536 and a collector between, if there is one.
def cuts_list(+c: U32) -> List<&2, U32>:
  Bool.pick(List<&2, U32>, U32.is_eq(c, 0), [0, 65536], [0, c, 65536])

def blocks_v(vs: List<&2, U32>, +seed: U32, +i: U32, +j: U32, +f: Frame, +u0: U32, +u1: U32, +sides: List<&2, Edge>, +cu: Edge, +cv: Edge, acc: List<&2, Blk>) -> List<&2, Blk>:
  match vs:
    case Nil{}:
      acc
    case Con{+v0, r}:
      match r:
        case Nil{}:
          acc
        case Con{+v1, r2}:
          +ss = Maybe.default(&2, Edge, List.get(&2, Edge, sides, 0n), no_edge())
          +sn = Maybe.default(&2, Edge, List.get(&2, Edge, sides, 1n), no_edge())
          +sw = Maybe.default(&2, Edge, List.get(&2, Edge, sides, 2n), no_edge())
          +se = Maybe.default(&2, Edge, List.get(&2, Edge, sides, 3n), no_edge())
          +es = edge_span(Bool.pick(Edge, U32.is_eq(v0, 0), ss, cv), u0, u1)
          +en = edge_span(Bool.pick(Edge, U32.is_eq(v1, 65536), sn, cv), u0, u1)
          +ew = edge_span(Bool.pick(Edge, U32.is_eq(u0, 0), sw, cu), v0, v1)
          +ee = edge_span(Bool.pick(Edge, U32.is_eq(u1, 65536), se, cu), v0, v1)
          blocks_v(r, seed, i, j, f, u0, u1, sides, cu, cv,
            List.append(&2, Blk, acc, blocks_of(river_row(j), seed, i, j, f, u0, u1, v0, v1, es, en, ew, ee)))

def blocks_u(us: List<&2, U32>, +vs: List<&2, U32>, +seed: U32, +i: U32, +j: U32, +f: Frame, +sides: List<&2, Edge>, +cu: Edge, +cv: Edge, acc: List<&2, Blk>) -> List<&2, Blk>:
  match us:
    case Nil{}:
      acc
    case Con{+u0, r}:
      match r:
        case Nil{}:
          acc
        case Con{+u1, r2}:
          blocks_u(r, vs, seed, i, j, f, sides, cu, cv, blocks_v(vs, seed, i, j, f, u0, u1, sides, cu, cv, acc))

def own_road(here: Bool, +seed: U32, +i: U32, +j: U32, +east: Bool, acc: List<&2, Line>) -> List<&2, Line>:
  match here:
    case False{}:
      acc
    case True{}:
      Line{road_code(i, j, east), Bool.pick(U32, east, 0, 9), road_pts(seed, i, j, east)} <> acc

def cut_line(here: Bool, +f: Frame, +fixed_u: Bool, +at: U32, acc: List<&2, Line>) -> List<&2, Line>:
  match here:
    case False{}:
      acc
    case True{}:
      Line{2, Bool.pick(U32, fixed_u, 1, 2), frame_pts(65n, f, fixed_u, at, 64, Nil{})} <> acc

def river_line(here: Bool, +seed: U32, +i: U32, +j: U32, +f: Frame, acc: List<&2, Line>) -> List<&2, Line>:
  match here:
    case False{}:
      acc
    case True{}:
      Line{0, 3, river_pts(25n, seed, i, j, f, 24, Nil{})} <> acc

def cell_sides(+seed: U32, +i: U32, +j: U32) -> List<&2, Edge>:
  [side_edge(seed, i, j, True{}), side_edge(seed, i, U32.add(j, 1), True{}),
   side_edge(seed, i, j, False{}), side_edge(seed, U32.add(i, 1), j, False{})]

# The collector across u (fixed_u) or across v, as the edge of a block.
def cut_edge(+f: Frame, +i: U32, +j: U32, +fixed_u: Bool, +at: U32, +other: U32) -> Edge:
  Edge{True{}, i, j, Bool.pick(U32, fixed_u, 3, 2), Bool.pick(U32, U32.is_eq(at, 0), 0, frame_line_length(f, fixed_u, at)),
    Bool.pick(U32, U32.is_eq(other, 0), far(), other), far(), 0, 0}

def cell_roads(+seed: U32, +i: U32, +j: U32, +f: Frame, +uc: U32, +vc: U32) -> List<&2, Line>:
  +own = own_road(has_road(seed, i, j, False{}), seed, i, j, False{}, own_road(has_road(seed, i, j, True{}), seed, i, j, True{}, Nil{}))
  +cuts = cut_line(U32.is_ne(vc, 0), f, False{}, vc, cut_line(U32.is_ne(uc, 0), f, True{}, uc, own))
  river_line(river_row(j), seed, i, j, f, cuts)

def cell_from(+f: Frame, +roads: List<&2, Line>, +blocks: List<&2, Blk>) -> Cell:
  Cell{f, List.reverse(&2, Line, blk_lines(blocks, f, roads)), blocks}

def cell_cut(+seed: U32, +i: U32, +j: U32, +f: Frame, +uc: U32, +vc: U32) -> Cell:
  +blocks = blocks_u(cuts_list(uc), cuts_list(vc), seed, i, j, f, cell_sides(seed, i, j),
              cut_edge(f, i, j, True{}, uc, vc), cut_edge(f, i, j, False{}, vc, uc), Nil{})
  cell_from(f, cell_roads(seed, i, j, f, uc, vc), blocks)

# The cell (i, j): its own roads, its collectors, its river, and its blocks
# with the streets inside them.
def cell_of(+seed: U32, +i: U32, +j: U32) -> Cell:
  +c = cell_cuts(seed, i, j)
  cell_cut(seed, i, j, frame_of(seed, i, j), cuts_u(c), cuts_v(c))

# The blocks of cell (i, j) with their streets, without the lines drawn for
# them: what the game needs to drive a lokal street, at a fraction of a cell.
def cell_blocks(+seed: U32, +i: U32, +j: U32) -> List<&2, Blk>:
  +c = cell_cuts(seed, i, j)
  +f = frame_of(seed, i, j)
  blocks_u(cuts_list(cuts_u(c)), cuts_list(cuts_v(c)), seed, i, j, f, cell_sides(seed, i, j),
    cut_edge(f, i, j, True{}, cuts_u(c), cuts_v(c)), cut_edge(f, i, j, False{}, cuts_v(c), cuts_u(c)), Nil{})
