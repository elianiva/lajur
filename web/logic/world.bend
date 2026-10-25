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
#     the limits PM 111/2015 Pasal 3 ayat (4) sets.
#
# Every one of these turns on a decision that takes a handful of values (a
# drop, a mouth position, a road class), so the laws walk every value the hash
# can pick, and no seed can break them.
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
