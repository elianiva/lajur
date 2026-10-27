# lajur — the town: The curves: the street between two junctions, and its branches.
# Part of town.bend, which names the town's functions for the page.
import Base
import ./lattice.bend as Lat

# ===========================================================================
# Curvature, from three numbers
#
# A cell of the wave spans `cells` blocks and swings by twice the amplitude,
# so its second difference per block is at most 48 * amplitude / cells ^ 2
# (the ease curve peaks at 6, and the block is 2 / cells of a half cell). The
# heading a node turns by is that second difference spread over one pitch, and
# the radius follows from the heading, so the whole town's tightest bend comes
# out of the three numbers above.
# ===========================================================================

def sag_cm() -> U32:
  U32.div(U32.mul(48, Lat.amp_cm()), U32.mul(Lat.cells(), Lat.cells()))

# The heading a node may turn by, in thousandths of a radian: the second
# difference spread over one pitch.
def turn_milli() -> U32:
  U32.div(U32.mul(sag_cm(), 1000), Lat.pitch_cm())

def radius_floor_cm() -> U32:
  U32.div(U32.mul(Lat.pitch_cm(), 1000), turn_milli())

# The furthest a node can move from its neighbour: the ease curve peaks at
# 1.5, so a block spans one block plus or minus six amplitudes over a cell.
def swing_cm() -> U32:
  U32.div(U32.mul(6, Lat.amp_cm()), Lat.cells())

# The closest two neighbouring nodes can come, and so the narrowest a block can
# get. Positive means no row ever folds.
def edge_cm() -> U32:
  U32.sub(Lat.pitch_cm(), swing_cm())

# ===========================================================================
# Branches
# ===========================================================================

type Dir is Data:
  North{}
  East{}
  South{}
  West{}

# The branch on a driver's left, for Pasal 113 ayat (1) huruf c and d. Traffic
# keeps left, so a driver heading north finds the west branch on their left.
def left_of(d: Dir) -> Dir:
  match d:
    case North{}:
      West{}
    case West{}:
      South{}
    case South{}:
      East{}
    case East{}:
      North{}

def right_of(d: Dir) -> Dir:
  match d:
    case North{}:
      East{}
    case East{}:
      South{}
    case South{}:
      West{}
    case West{}:
      North{}

# A local street sometimes stops short, and the junction it would have made
# becomes a T. The pattern is fixed rather than seeded: the skeleton of the
# town is authored, and the seed moves it rather than rerouting it. Only east
# links go, so no node can lose more than two branches and keep none.
def cut(+i: U32, +j: U32) -> Bool:
  Bool.and(Bool.not(Lat.major_row(j)), U32.is_eq(U32.mod(U32.add(U32.mul(i, 3), U32.mul(j, 5)), 13), 0))

def has(+i: U32, +j: U32, d: Dir) -> Bool:
  match d:
    case North{}:
      U32.is_lt(0, j)
    case South{}:
      U32.is_lt(j, U32.sub(Lat.rows(), 1))
    case West{}:
      Bool.and(U32.is_lt(0, i),
               Bool.or(U32.is_ne(U32.sub(i, 1), Lat.river_gap()), Lat.bridge(j)))
    case East{}:
      Bool.and(U32.is_lt(i, U32.sub(Lat.cols(), 1)),
               Bool.and(Bool.not(cut(i, j)),
                        Bool.or(U32.is_ne(i, Lat.river_gap()), Lat.bridge(j))))

def end_of(i: U32, j: U32, d: Dir, seed: U32) -> Lat.Pt:
  match d:
    case North{}:
      Lat.site(i, U32.sub(j, 1), seed)
    case South{}:
      Lat.site(i, U32.add(j, 1), seed)
    case East{}:
      Lat.site(U32.add(i, 1), j, seed)
    case West{}:
      Lat.site(U32.sub(i, 1), j, seed)

# ===========================================================================
# The street between two junctions
#
# A Catmull-Rom spline through the nodes: a segment's handles point a sixth of
# the way to the neighbour beyond each end, so the tangent is continuous at
# every junction and a row reads as one road, not a run of chords.
# ===========================================================================

# A difference in centimetres, for the curve. `diff` answers metres, which is
# what the angle tests want; a curve wants the centimetres.
def gap_cm(near: U32, far: U32) -> Lat.Signed:
  +raw = U32.sub(far, near)
  +down = U32.is_gt(raw, 2147483647)
  Lat.Signed{Bool.pick(U32, down, U32.sub(0, raw), raw), down}

# A point a fraction `t` of the way from a to b, in thousand-and-twenty-fourths.
def lerp(+a: U32, +b: U32, t: U32) -> U32:
  +d = gap_cm(a, b)
  Lat.place(a, U32.shrn(U32.mul(Lat.span(d), t), 10n), Lat.below(d))

def sixth(a: U32, b: U32) -> Lat.Signed:
  +d = gap_cm(a, b)
  Lat.Signed{U32.div(Lat.span(d), 6), Lat.below(d)}

def push(p: Lat.Pt, +dx: Lat.Signed, +dz: Lat.Signed) -> Lat.Pt:
  match p:
    case Lat.Pt{x, z}:
      Lat.Pt{Lat.place(x, Lat.span(dx), Lat.below(dx)), Lat.place(z, Lat.span(dz), Lat.below(dz))}

def minus_one(+k: U32) -> U32:
  U32.sub(k, U32.min(k, 1))

def minus_two(+k: U32) -> U32:
  U32.sub(k, U32.min(k, 2))

def plus_one(+k: U32, limit: U32) -> U32:
  U32.min(U32.add(k, 1), limit)

def plus_two(+k: U32, limit: U32) -> U32:
  U32.min(U32.add(k, 2), limit)

# The node one step behind the start of a link.
def behind(+i: U32, +j: U32, d: Dir, +seed: U32) -> Lat.Pt:
  match d:
    case East{}:
      Lat.site(minus_one(i), j, seed)
    case West{}:
      Lat.site(plus_one(i, U32.sub(Lat.cols(), 1)), j, seed)
    case South{}:
      Lat.site(i, minus_one(j), seed)
    case North{}:
      Lat.site(i, plus_one(j, U32.sub(Lat.rows(), 1)), seed)

# The node one step beyond the end of a link.
def onward(+i: U32, +j: U32, d: Dir, +seed: U32) -> Lat.Pt:
  match d:
    case East{}:
      Lat.site(plus_two(i, U32.sub(Lat.cols(), 1)), j, seed)
    case West{}:
      Lat.site(minus_two(i), j, seed)
    case South{}:
      Lat.site(i, plus_two(j, U32.sub(Lat.rows(), 1)), seed)
    case North{}:
      Lat.site(i, minus_two(j), seed)

def handle_a(p0: Lat.Pt, p1: Lat.Pt, p2: Lat.Pt) -> Lat.Pt:
  match p0:
    case Lat.Pt{x0, z0}:
      match p1:
        case Lat.Pt{x1, z1}:
          match p2:
            case Lat.Pt{x2, z2}:
              push(Lat.Pt{x1, z1}, sixth(x0, x2), sixth(z0, z2))

def step_back(p: Lat.Pt, dx: Lat.Signed, dz: Lat.Signed) -> Lat.Pt:
  match p:
    case Lat.Pt{x, z}:
      match dx:
        case Lat.Signed{sx, down_x}:
          match dz:
            case Lat.Signed{sz, down_z}:
              Lat.Pt{Lat.place(x, sx, Bool.not(down_x)), Lat.place(z, sz, Bool.not(down_z))}

def handle_b(p1: Lat.Pt, p2: Lat.Pt, p3: Lat.Pt) -> Lat.Pt:
  match p1:
    case Lat.Pt{x1, z1}:
      match p2:
        case Lat.Pt{x2, z2}:
          match p3:
            case Lat.Pt{x3, z3}:
              step_back(Lat.Pt{x2, z2}, sixth(x1, x3), sixth(z1, z3))

type Curve is Data:
  Curve{start: Lat.Pt, out: Lat.Pt, back: Lat.Pt, end: Lat.Pt}

def curve_of(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Curve:
  +p0 = behind(i, j, d, seed)
  +p1 = Lat.site(i, j, seed)
  +p2 = end_of(i, j, d, seed)
  +p3 = onward(i, j, d, seed)
  Curve{p1, handle_a(p0, p1, p2), handle_b(p1, p2, p3), p2}

def bezier(a: Lat.Pt, b: Lat.Pt, c: Lat.Pt, e: Lat.Pt, +t: U32) -> Lat.Pt:
  match a:
    case Lat.Pt{+ax, +az}:
      match b:
        case Lat.Pt{+bx, +bz}:
          match c:
            case Lat.Pt{+cx, +cz}:
              match e:
                case Lat.Pt{+ex, +ez}:
                  +abx = lerp(ax, bx, t)
                  +abz = lerp(az, bz, t)
                  +bcx = lerp(bx, cx, t)
                  +bcz = lerp(bz, cz, t)
                  +cex = lerp(cx, ex, t)
                  +cez = lerp(cz, ez, t)
                  +abcx = lerp(abx, bcx, t)
                  +abcz = lerp(abz, bcz, t)
                  +bcex = lerp(bcx, cex, t)
                  +bcez = lerp(bcz, cez, t)
                  Lat.Pt{lerp(abcx, bcex, t), lerp(abcz, bcez, t)}

def at(c: Curve, +t: U32) -> Lat.Pt:
  match c:
    case Curve{start, out, back, end}:
      bezier(start, out, back, end, t)

type Sample is Data:
  Sample{x: U32, z: U32, dx: Lat.Signed, dz: Lat.Signed}

# How many steps a street is drawn in: eight, one every nine metres.
def measures() -> U32:
  8

# The way forward: the step to the next sample, or to this one from the last at
# the end of the street.
def carry(+forward: Lat.Signed, +backward: Lat.Signed) -> Lat.Signed:
  match forward:
    case Lat.Signed{fs, fd}:
      match backward:
        case Lat.Signed{bs, bd}:
          Bool.pick(Lat.Signed, U32.is_eq(fs, 0), Lat.Signed{bs, Bool.not(bd)}, Lat.Signed{fs, fd})

# The point, and the way it heads: forward from the last sample to the next.
def sample_of(here: Lat.Pt, back: Lat.Pt, there: Lat.Pt) -> Sample:
  match here:
    case Lat.Pt{+hx, +hz}:
      match back:
        case Lat.Pt{+lx, +lz}:
          match there:
            case Lat.Pt{+rx, +rz}:
              Sample{hx, hz, carry(gap_cm(hx, rx), gap_cm(hx, lx)),
                     carry(gap_cm(hz, rz), gap_cm(hz, lz))}

# One point on a street, and the way it is heading: `k` from 0 to `measures`.
def sample_at(+i: U32, +j: U32, +d: Dir, +k: U32, +seed: U32) -> Sample:
  +c = curve_of(i, j, d, seed)
  +step = U32.div(1024, measures())
  +t = U32.div(U32.mul(k, 1024), measures())
  +lo = Bool.pick(U32, U32.is_eq(k, 0), 0, U32.sub(t, step))
  +hi = Bool.pick(U32, U32.is_eq(k, measures()), t, U32.add(t, step))
  sample_of(at(c, t), at(c, lo), at(c, hi))

def gather(fuel: Nat, +k: U32, +i: U32, +j: U32, +d: Dir, +seed: U32) -> List<Sample>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+p:
      sample_at(i, j, d, k, seed) <> gather(p, U32.add(k, 1), i, j, d, seed)

def samples(+i: U32, +j: U32, +d: Dir, +seed: U32) -> List<Sample>:
  gather(U32.to_nat(U32.add(measures(), 1)), 0, i, j, d, seed)

# Every sample of a street falls inside the canvas.
def sample_inside(s: Sample) -> Bool:
  match s:
    case Sample{x, z, dx, dz}:
      Bool.and(U32.is_le(x, 90000), U32.is_le(z, 90000))

def sample_count(xs: List<Sample>) -> U32:
  match xs:
    case Nil{}:
      0
    case +h <> t:
      U32.add(1, sample_count(t))

def samples_inside(xs: List<Sample>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case +h <> t:
      Bool.and(sample_inside(h), samples_inside(t))

def branches(+i: U32, +j: U32) -> U32:
  U32.add(U32.add(Bool.to_u32(has(i, j, North{})), Bool.to_u32(has(i, j, East{}))),
          U32.add(Bool.to_u32(has(i, j, South{})), Bool.to_u32(has(i, j, West{}))))

type Vec is Data:
  Vec{x: Lat.Signed, z: Lat.Signed}

def vec_of(here: Lat.Pt, there: Lat.Pt) -> Vec:
  match here:
    case Lat.Pt{hx, hz}:
      match there:
        case Lat.Pt{tx, tz}:
          Vec{Lat.diff(hx, tx), Lat.diff(hz, tz)}

def leg(+i: U32, +j: U32, d: Dir, +seed: U32) -> Vec:
  vec_of(Lat.site(i, j, seed), end_of(i, j, d, seed))

# The direction a three-way junction does without. A four-way junction has no
# missing branch, and this only answers one when the caller has counted three.
def missing_of(n: Bool, e: Bool, s: Bool, w: Bool) -> Dir:
  match n:
    case False{}:
      North{}
    case True{}:
      match e:
        case False{}:
          East{}
        case True{}:
          match s:
            case False{}:
              South{}
            case True{}:
              West{}

# The direction of travel through a junction, by how far the two legs bend. A
# straight T has two legs that face each other; a skew T's do not.
def straight_legs(a: Vec, b: Vec) -> Bool:
  match a:
    case Vec{+ax, +az}:
      match b:
        case Vec{+bx, +bz}:
          +wx = Lat.plus(ax, bx)
          +wz = Lat.plus(az, bz)
          +bent = U32.mul(100, U32.add(Lat.span(wx), Lat.span(wz)))
          +run = U32.add(U32.add(Lat.span(ax), Lat.span(az)), U32.add(Lat.span(bx), Lat.span(bz)))
          U32.is_le(bent, U32.mul(18, run))

# Eighteen parts in a hundred is ten degrees either side of opposite.
def through(+i: U32, +j: U32, gone: Dir, +seed: U32) -> Bool:
  match gone:
    case North{}:
      straight_legs(leg(i, j, East{}, seed), leg(i, j, West{}, seed))
    case South{}:
      straight_legs(leg(i, j, East{}, seed), leg(i, j, West{}, seed))
    case East{}:
      straight_legs(leg(i, j, North{}, seed), leg(i, j, South{}, seed))
    case West{}:
      straight_legs(leg(i, j, North{}, seed), leg(i, j, South{}, seed))
