# lajur — the town: a warped lattice of streets, its junctions and their duties.
#
# Eleven columns by nine rows of junctions, seventy metres apart. A smooth
# two-dimensional wave moves every node, and that wave is the only source of
# curvature in the town: its amplitude, its cell and the pitch decide every
# radius in it, so PROOF.bend can bound the town's tightest bend from three
# numbers instead of sampling geometry.
#
# Index decides class. Every fourth column and row is a collector, and the
# boundary is the ring. Geometry decides the junction's shape, because a T on a
# bend is a skew T (Pasal 113 ayat (1) huruf d) and a T on a straight is a
# perpendicular T (huruf e). The field makes both, so the curvature is the
# curriculum and not the decoration.
import Base

# ===========================================================================
# The lattice
# ===========================================================================

# Junction count on each axis. Ten block sides each way.
def cols() -> U32:
  11

def rows() -> U32:
  9

# Centre to centre, in centimetres.
def pitch_cm() -> U32:
  7000

# The first node sits this far from the town's edge, so the outermost bend of
# the field and the curve handles beyond it stay inside the canvas, and no
# coordinate can wrap below zero.
def margin_cm() -> U32:
  8000

# The field moves a node by at most this much, each way.
def amp_cm() -> U32:
  4000

# The field repeats over this many blocks. Longer is a sweep, shorter is a
# slalom; six blocks at forty metres is a street that visibly bends once
# across the view.
def cells() -> U32:
  6

# The town the game ships.
def seed_of_town() -> U32:
  20261024

# A collector runs along every fourth column and row; the edge is the ring.
def major_col(i: U32) -> Bool:
  U32.is_eq(U32.mod(i, 4), 0)

def major_row(j: U32) -> Bool:
  U32.is_eq(U32.mod(j, 4), 0)

# The river runs between column seven and column eight, and only the two
# bridges cross it. That is the town's one edge, and every bridge approach is
# a T junction.
def river_gap() -> U32:
  7

def bridge(+j: U32) -> Bool:
  Bool.or(U32.is_eq(j, 1), U32.is_eq(j, 5))

# ===========================================================================
# Signed whole numbers
#
# Bend has no I32, and a lattice needs differences. A difference is stored as
# a size and a direction. Subtraction wraps, and a true negative lands above
# two to the thirty-first, which is how `diff` reads it back.
# ===========================================================================

type Signed is Data:
  Signed{size: U32, down: Bool}

def diff(near: U32, far: U32) -> Signed:
  +raw = U32.sub(far, near)
  +down = U32.is_gt(raw, 2147483647)
  Signed{U32.div(Bool.pick(U32, down, U32.sub(0, raw), raw), 100), down}

def span(s: Signed) -> U32:
  match s:
    case Signed{size, down}:
      size

def below(s: Signed) -> Bool:
  match s:
    case Signed{size, down}:
      down

def keep(big: U32, small: U32, down: Bool) -> Signed:
  Signed{U32.sub(big, small), down}

def combine(+as: U32, +ad: Bool, +bs: U32, +bd: Bool) -> Signed:
  match ad:
    case True{}:
      match bd:
        case True{}:
          Signed{U32.add(as, bs), True{}}
        case False{}:
          Bool.pick(Signed, U32.is_le(as, bs), keep(bs, as, False{}), keep(as, bs, True{}))
    case False{}:
      match bd:
        case True{}:
          Bool.pick(Signed, U32.is_le(as, bs), keep(bs, as, True{}), keep(as, bs, False{}))
        case False{}:
          Signed{U32.add(as, bs), False{}}

def plus(a: Signed, b: Signed) -> Signed:
  match a:
    case Signed{as, ad}:
      match b:
        case Signed{bs, bd}:
          combine(as, ad, bs, bd)

# Whether the first is at least as far from zero as the second.
def at_least(a: Signed, b: Signed) -> Bool:
  match a:
    case Signed{as, ad}:
      match b:
        case Signed{bs, bd}:
          U32.is_le(bs, as)

# ===========================================================================
# The field
#
# A periodic wave, not a random field. A random field moves whole rows without
# bending them: its second difference is a fraction of its swing, so a dense
# lattice comes out straight. A wave that swings across its whole cell bends
# every row by a known amount, which is what makes the radius provable.
#
# Each row starts the wave at a different phase, so the town is a fabric and
# not a set of parallel waves. The phase drifts one or two blocks a row, far
# below the fold limit.
# ===========================================================================

def mix(id: U32, tick: U32) -> U32:
  U32.add(U32.mul(U32.add(id, 1), 2654435761), U32.mul(tick, 40503))

# The ease curve: zero slope at both ends, so the wave has no corner where one
# cell meets the next.
def ease(+frac: U32) -> U32:
  +square = U32.div(U32.mul(frac, frac), 1000)
  +cube = U32.div(U32.mul(square, frac), 1000)
  U32.sub(U32.mul(3, square), U32.mul(2, cube))

# One wave, 0..1000, full swing once across `cells` blocks: up over the first
# half, down over the second. Eased twice, so the curvature is continuous
# where two cells meet and the crest is a flat, not a corner. `t` runs in
# thousandths of a block, so a row can start its wave between two nodes.
def bump(+t: U32) -> U32:
  +whole = U32.mul(cells(), 1000)
  +half = U32.mul(t, 2)
  +rise = U32.is_lt(half, whole)
  +up = U32.div(U32.mul(half, 1000), whole)
  +down = U32.div(U32.mul(U32.sub(U32.mul(whole, 2), half), 1000), whole)
  ease(Bool.pick(U32, rise, up, down))

# How far a row's wave has slid by the time it reaches a column, in thousandths
# of a block per row: about an eighth of a block, so the rows drift against
# each other without shearing the lattice apart.
def drift(seed: U32) -> U32:
  U32.add(80, U32.mod(mix(3, seed), 80))

def shift(+i: U32, j: U32, seed: U32) -> U32:
  U32.add(U32.mul(i, 1000), U32.mul(j, drift(seed)))

def wave(+i: U32, j: U32, seed: U32) -> U32:
  bump(U32.mod(shift(i, j, seed), U32.mul(cells(), 1000)))

# How far the field moves a node, in centimetres: zero at 500, the amplitude
# at either end of its range.
def travel(+v: U32) -> U32:
  +down = U32.is_lt(v, 500)
  U32.div(U32.mul(Bool.pick(U32, down, U32.sub(500, v), U32.sub(v, 500)), amp_cm()), 500)

def place(base: U32, dist: U32, down: Bool) -> U32:
  match down:
    case True{}:
      U32.sub(base, dist)
    case False{}:
      U32.add(base, dist)

# One coordinate of a node, in centimetres. `along` asks for the x axis; the
# other axis takes a seed far enough away that the two never agree.
def axis(+i: U32, +j: U32, +seed: U32, +along: Bool) -> U32:
  +a = Bool.pick(U32, along, i, j)
  +b = Bool.pick(U32, along, j, i)
  +v = wave(b, a, seed)
  +base = U32.add(margin_cm(), U32.mul(a, pitch_cm()))
  place(base, travel(v), U32.is_lt(v, 500))

type Pt is Data:
  Pt{x: U32, z: U32}

def site(+i: U32, +j: U32, +seed: U32) -> Pt:
  Pt{axis(i, j, seed, True{}), axis(i, j, U32.add(seed, 977), False{})}

def pt_x(p: Pt) -> U32:
  match p:
    case Pt{x, z}:
      x

def pt_z(p: Pt) -> U32:
  match p:
    case Pt{x, z}:
      z

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
  U32.div(U32.mul(48, amp_cm()), U32.mul(cells(), cells()))

# The heading a node may turn by, in thousandths of a radian: the second
# difference spread over one pitch.
def turn_milli() -> U32:
  U32.div(U32.mul(sag_cm(), 1000), pitch_cm())

def radius_floor_cm() -> U32:
  U32.div(U32.mul(pitch_cm(), 1000), turn_milli())

# The furthest a node can move from its neighbour: the ease curve peaks at
# 1.5, so a block spans one block plus or minus six amplitudes over a cell.
def swing_cm() -> U32:
  U32.div(U32.mul(6, amp_cm()), cells())

# The closest two neighbouring nodes can come, and so the narrowest a block can
# get. Positive means no row ever folds.
def edge_cm() -> U32:
  U32.sub(pitch_cm(), swing_cm())

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

# A local street sometimes stops short, and the junction it would have made
# becomes a T. The pattern is fixed rather than seeded: the skeleton of the
# town is authored, and the seed moves it rather than rerouting it. Only east
# links go, so no node can lose more than two branches and keep none.
def cut(+i: U32, +j: U32) -> Bool:
  Bool.and(Bool.not(major_row(j)), U32.is_eq(U32.mod(U32.add(U32.mul(i, 3), U32.mul(j, 5)), 13), 0))

def has(+i: U32, +j: U32, d: Dir) -> Bool:
  match d:
    case North{}:
      U32.is_lt(0, j)
    case South{}:
      U32.is_lt(j, U32.sub(rows(), 1))
    case West{}:
      Bool.and(U32.is_lt(0, i),
               Bool.or(U32.is_ne(U32.sub(i, 1), river_gap()), bridge(j)))
    case East{}:
      Bool.and(U32.is_lt(i, U32.sub(cols(), 1)),
               Bool.and(Bool.not(cut(i, j)),
                        Bool.or(U32.is_ne(i, river_gap()), bridge(j))))

def end_of(i: U32, j: U32, d: Dir, seed: U32) -> Pt:
  match d:
    case North{}:
      site(i, U32.sub(j, 1), seed)
    case South{}:
      site(i, U32.add(j, 1), seed)
    case East{}:
      site(U32.add(i, 1), j, seed)
    case West{}:
      site(U32.sub(i, 1), j, seed)

# ===========================================================================
# The street between two junctions
#
# A Catmull-Rom spline through the nodes: a segment's handles point a sixth of
# the way to the neighbour beyond each end, so the tangent is continuous at
# every junction and a row reads as one road, not a run of chords.
# ===========================================================================

# A difference in centimetres, for the curve. `diff` answers metres, which is
# what the angle tests want; a curve wants the centimetres.
def gap_cm(near: U32, far: U32) -> Signed:
  +raw = U32.sub(far, near)
  +down = U32.is_gt(raw, 2147483647)
  Signed{Bool.pick(U32, down, U32.sub(0, raw), raw), down}

# A point a fraction `t` of the way from a to b, in thousand-and-twenty-fourths.
def lerp(+a: U32, +b: U32, t: U32) -> U32:
  +d = gap_cm(a, b)
  place(a, U32.div(U32.mul(span(d), t), 1024), below(d))

def sixth(a: U32, b: U32) -> Signed:
  +d = gap_cm(a, b)
  Signed{U32.div(span(d), 6), below(d)}

def push(p: Pt, +dx: Signed, +dz: Signed) -> Pt:
  match p:
    case Pt{x, z}:
      Pt{place(x, span(dx), below(dx)), place(z, span(dz), below(dz))}

def minus_one(+k: U32) -> U32:
  U32.sub(k, U32.min(k, 1))

def minus_two(+k: U32) -> U32:
  U32.sub(k, U32.min(k, 2))

def plus_one(+k: U32, limit: U32) -> U32:
  U32.min(U32.add(k, 1), limit)

def plus_two(+k: U32, limit: U32) -> U32:
  U32.min(U32.add(k, 2), limit)

# The node one step behind the start of a link.
def behind(+i: U32, +j: U32, d: Dir, +seed: U32) -> Pt:
  match d:
    case East{}:
      site(minus_one(i), j, seed)
    case West{}:
      site(plus_one(i, U32.sub(cols(), 1)), j, seed)
    case South{}:
      site(i, minus_one(j), seed)
    case North{}:
      site(i, plus_one(j, U32.sub(rows(), 1)), seed)

# The node one step beyond the end of a link.
def onward(+i: U32, +j: U32, d: Dir, +seed: U32) -> Pt:
  match d:
    case East{}:
      site(plus_two(i, U32.sub(cols(), 1)), j, seed)
    case West{}:
      site(minus_two(i), j, seed)
    case South{}:
      site(i, plus_two(j, U32.sub(rows(), 1)), seed)
    case North{}:
      site(i, minus_two(j), seed)

def handle_a(p0: Pt, p1: Pt, p2: Pt) -> Pt:
  match p0:
    case Pt{x0, z0}:
      match p1:
        case Pt{x1, z1}:
          match p2:
            case Pt{x2, z2}:
              push(Pt{x1, z1}, sixth(x0, x2), sixth(z0, z2))

def step_back(p: Pt, dx: Signed, dz: Signed) -> Pt:
  match p:
    case Pt{x, z}:
      match dx:
        case Signed{sx, down_x}:
          match dz:
            case Signed{sz, down_z}:
              Pt{place(x, sx, Bool.not(down_x)), place(z, sz, Bool.not(down_z))}

def handle_b(p1: Pt, p2: Pt, p3: Pt) -> Pt:
  match p1:
    case Pt{x1, z1}:
      match p2:
        case Pt{x2, z2}:
          match p3:
            case Pt{x3, z3}:
              step_back(Pt{x2, z2}, sixth(x1, x3), sixth(z1, z3))

type Curve is Data:
  Curve{start: Pt, out: Pt, back: Pt, end: Pt}

def curve_of(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Curve:
  +p0 = behind(i, j, d, seed)
  +p1 = site(i, j, seed)
  +p2 = end_of(i, j, d, seed)
  +p3 = onward(i, j, d, seed)
  Curve{p1, handle_a(p0, p1, p2), handle_b(p1, p2, p3), p2}

def bezier(a: Pt, b: Pt, c: Pt, e: Pt, +t: U32) -> Pt:
  match a:
    case Pt{+ax, +az}:
      match b:
        case Pt{+bx, +bz}:
          match c:
            case Pt{+cx, +cz}:
              match e:
                case Pt{+ex, +ez}:
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
                  Pt{lerp(abcx, bcex, t), lerp(abcz, bcez, t)}

def at(c: Curve, +t: U32) -> Pt:
  match c:
    case Curve{start, out, back, end}:
      bezier(start, out, back, end, t)

type Sample is Data:
  Sample{x: U32, z: U32, dx: Signed, dz: Signed}

# How many steps a street is drawn in: eight, one every nine metres.
def measures() -> U32:
  8

# The way forward: the step to the next sample, or to this one from the last at
# the end of the street.
def carry(+forward: Signed, +backward: Signed) -> Signed:
  match forward:
    case Signed{fs, fd}:
      match backward:
        case Signed{bs, bd}:
          Bool.pick(Signed, U32.is_eq(fs, 0), Signed{bs, Bool.not(bd)}, Signed{fs, fd})

# The point, and the way it heads: forward from the last sample to the next.
def sample_of(here: Pt, back: Pt, there: Pt) -> Sample:
  match here:
    case Pt{+hx, +hz}:
      match back:
        case Pt{+lx, +lz}:
          match there:
            case Pt{+rx, +rz}:
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
  Vec{x: Signed, z: Signed}

def vec_of(here: Pt, there: Pt) -> Vec:
  match here:
    case Pt{hx, hz}:
      match there:
        case Pt{tx, tz}:
          Vec{diff(hx, tx), diff(hz, tz)}

def leg(+i: U32, +j: U32, d: Dir, +seed: U32) -> Vec:
  vec_of(site(i, j, seed), end_of(i, j, d, seed))

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
          +wx = plus(ax, bx)
          +wz = plus(az, bz)
          +bent = U32.mul(100, U32.add(span(wx), span(wz)))
          +run = U32.add(U32.add(span(ax), span(az)), U32.add(span(bx), span(bz)))
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

# ===========================================================================
# The junction's shape and its duty
# ===========================================================================

type Shape is Data:
  FourEqual{}
  FourMajor{}
  StraightT{}
  SkewT{}
  Bend{}

type Control is Data:
  Signal{}
  Roundabout{}
  Uncontrolled{}

type Duty is Data:
  ObeySignal{}
  YieldRight{}
  YieldMain{}
  YieldLeft{}
  YieldThrough{}
  FreePassage{}

def differ(a: Bool, b: Bool) -> Bool:
  match a:
    case True{}:
      Bool.not(b)
    case False{}:
      b

def shape_of(count: U32, split: Bool, straight: Bool) -> Shape:
  match count:
    case 4:
      Bool.pick(Shape, split, FourMajor{}, FourEqual{})
    case 3:
      Bool.pick(Shape, straight, StraightT{}, SkewT{})
    case _:
      Bend{}

def shape(+i: U32, +j: U32, +seed: U32) -> Shape:
  shape_of(branches(i, j),
           differ(major_col(i), major_row(j)),
           through(i, j, missing_of(has(i, j, North{}), has(i, j, East{}),
                                    has(i, j, South{}), has(i, j, West{})), seed))

# The town's heart, where the two avenues cross, is a bundaran. Every other
# crossing of two collectors is signalised.
def heart(i: U32, j: U32) -> Bool:
  Bool.and(U32.is_eq(i, 4), U32.is_eq(j, 4))

def control_of(in_heart: Bool, both: Bool) -> Control:
  match in_heart:
    case True{}:
      Roundabout{}
    case False{}:
      match both:
        case True{}:
          Signal{}
        case False{}:
          Uncontrolled{}

def control(+i: U32, +j: U32) -> Control:
  +crossing = Bool.and(major_col(i), major_row(j))
  +wide = U32.is_le(3, branches(i, j))
  control_of(heart(i, j), Bool.and(crossing, wide))

def duty_of(control: Control, shape: Shape) -> Duty:
  match control:
    case Signal{}:
      ObeySignal{}
    case Roundabout{}:
      YieldRight{}
    case Uncontrolled{}:
      match shape:
        case FourEqual{}:
          YieldLeft{}
        case SkewT{}:
          YieldLeft{}
        case FourMajor{}:
          YieldMain{}
        case StraightT{}:
          YieldThrough{}
        case Bend{}:
          FreePassage{}

def duty(+i: U32, +j: U32, seed: U32) -> Duty:
  duty_of(control(i, j), shape(i, j, seed))

# Every node of the lattice, counted down from the last, asking whether it still
# has a street to leave by.
def every_node_wide(fuel: Nat, +n: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +i = U32.mod(n, cols())
      +j = U32.div(n, cols())
      Bool.and(U32.is_le(2, branches(i, j)), every_node_wide(p, U32.add(n, 1)))

# ===========================================================================
# The signal plan
#
# Two phases, one per axis, twenty-six seconds a cycle: eleven green, two
# yellow, then the other axis. The pairs never overlap, so no two conflicting
# approaches ever see green together.
# ===========================================================================

def cycle() -> U32:
  26

def green_at(phase: U32, +tick: U32) -> Bool:
  match phase:
    case 0:
      U32.is_lt(U32.mod(tick, cycle()), 11)
    case _:
      Bool.and(U32.is_le(13, U32.mod(tick, cycle())), U32.is_lt(U32.mod(tick, cycle()), 24))

# Every tick of a cycle, checked by counting down a Nat.
def phases_disjoint(fuel: Nat, +tick: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +apart = Bool.not(Bool.and(green_at(0, tick), green_at(1, tick)))
      Bool.and(apart, phases_disjoint(p, U32.add(tick, 1)))

def green_of(c: Control, d: Dir, tick: U32) -> Bool:
  match c:
    case Signal{}:
      match d:
        case North{}:
          green_at(0, tick)
        case South{}:
          green_at(0, tick)
        case East{}:
          green_at(1, tick)
        case West{}:
          green_at(1, tick)
    case Roundabout{}:
      True{}
    case Uncontrolled{}:
      True{}

def green(i: U32, j: U32, d: Dir, tick: U32) -> Bool:
  green_of(control(i, j), d, tick)

# ===========================================================================
# Street furniture at the junction
#
# Each approach carries what the statute puts there: a stop line and a head at
# a signal, a give-way line and its sign where a road must give priority, and
# the priority warning on the road that is given it (PM 13/2014 Pasal 61 pairs
# the two signs, one on each side of the give-way).
# ===========================================================================

type Street is Data:
  Ring{}
  Collector{}
  Local{}

def row_street(on_first: Bool, on_last: Bool, major: Bool) -> Street:
  match on_first:
    case True{}:
      Ring{}
    case False{}:
      match on_last:
        case True{}:
          Ring{}
        case False{}:
          match major:
            case True{}:
              Collector{}
            case False{}:
              Local{}

# The street an approach belongs to. East and west run along row j; north and
# south run along column i; the first and last of each is the ring.
def street_of(+i: U32, +j: U32, d: Dir) -> Street:
  match d:
    case East{}:
      row_street(U32.is_eq(j, 0), U32.is_eq(j, U32.sub(rows(), 1)), major_row(j))
    case West{}:
      row_street(U32.is_eq(j, 0), U32.is_eq(j, U32.sub(rows(), 1)), major_row(j))
    case North{}:
      row_street(U32.is_eq(i, 0), U32.is_eq(i, U32.sub(cols(), 1)), major_col(i))
    case South{}:
      row_street(U32.is_eq(i, 0), U32.is_eq(i, U32.sub(cols(), 1)), major_col(i))

# Half the carriageway, in centimetres: fourteen metres across on the ring,
# nine on a collector, six on a local street.
def half_cm(s: Street) -> U32:
  match s:
    case Ring{}:
      700
    case Collector{}:
      450
    case Local{}:
      300

type Mark is Data:
  StopLine{}
  GiveWayLine{}
  NoLine{}

type Post is Data:
  PriorityWarning{}
  GiveWaySign{}
  StopSign{}
  NoSign{}

type Approach is Data:
  Approach{d: Dir, present: Bool, half: U32, mark: Mark, line_cm: U32, zebra_cm: U32,
           head: Bool, post: Post}

def opposite(d: Dir) -> Dir:
  match d:
    case North{}:
      South{}
    case South{}:
      North{}
    case East{}:
      West{}
    case West{}:
      East{}

def is_eq_dir(a: Dir, b: Dir) -> Bool:
  match a:
    case North{}:
      match b:
        case North{}:
          True{}
        case _:
          False{}
    case South{}:
      match b:
        case South{}:
          True{}
        case _:
          False{}
    case East{}:
      match b:
        case East{}:
          True{}
        case _:
          False{}
    case West{}:
      match b:
        case West{}:
          True{}
        case _:
          False{}

def minor_of(+i: U32, +j: U32, d: Dir) -> Bool:
  match d:
    case North{}:
      Bool.not(major_col(i))
    case South{}:
      Bool.not(major_col(i))
    case East{}:
      Bool.not(major_row(j))
    case West{}:
      Bool.not(major_row(j))

# Which approach must give way, when one of them must. At a four-way with a
# main road the minor road does; at a perpendicular T the stem does; at a skew
# T nobody is posted, because the statute's rule there is the general yield to
# the left (Pasal 113 ayat (1) huruf d) and not a sign.
def gives_way(shape: Shape, minor: Bool, stem: Bool) -> Bool:
  match shape:
    case FourMajor{}:
      minor
    case StraightT{}:
      stem
    case FourEqual{}:
      False{}
    case SkewT{}:
      False{}
    case Bend{}:
      False{}

# Whether the junction posts a give-way at all. A skew T and an equal
# four-way do not: their rule is the general one, and PM 13/2014 Pasal 61 pairs
# a priority warning with a give-way sign, so a junction with one sign carries
# the other.
def has_give_way(control: Control, shape: Shape) -> Bool:
  match control:
    case Signal{}:
      False{}
    case Roundabout{}:
      True{}
    case Uncontrolled{}:
      match shape:
        case FourMajor{}:
          True{}
        case StraightT{}:
          True{}
        case _:
          False{}

def mark_of(control: Control, gives: Bool) -> Mark:
  match control:
    case Signal{}:
      StopLine{}
    case Roundabout{}:
      GiveWayLine{}
    case Uncontrolled{}:
      match gives:
        case True{}:
          GiveWayLine{}
        case False{}:
          NoLine{}

def post_of(control: Control, gives: Bool, given: Bool) -> Post:
  match control:
    case Signal{}:
      NoSign{}
    case Roundabout{}:
      GiveWaySign{}
    case Uncontrolled{}:
      match gives:
        case True{}:
          GiveWaySign{}
        case False{}:
          match given:
            case True{}:
              PriorityWarning{}
            case False{}:
              NoSign{}

def signal_head(control: Control) -> Bool:
  match control:
    case Signal{}:
      True{}
    case Roundabout{}:
      False{}
    case Uncontrolled{}:
      False{}

# The line stands two metres off the carriageway it is crossing; the crossing
# further back than the line. A local street with no line has no crossing.
def line_cm(half: U32) -> U32:
  U32.add(half, 200)

def crossing_cm(control: Control, street: Street, half: U32) -> U32:
  match control:
    case Signal{}:
      U32.add(half, 900)
    case Roundabout{}:
      0
    case Uncontrolled{}:
      match street:
        case Ring{}:
          U32.add(half, 900)
        case Collector{}:
          U32.add(half, 900)
        case Local{}:
          0

def approach_of(d: Dir, present: Bool, +half: U32, street: Street, +c: Control,
                +gives: Bool, +given: Bool) -> Approach:
  Approach{d, present, half, mark_of(c, gives), line_cm(half), crossing_cm(c, street, half),
           signal_head(c), post_of(c, gives, given)}

def approach_at(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Approach:
  +c = control(i, j)
  +s = shape(i, j, seed)
  +street = street_of(i, j, d)
  +gone = missing_of(has(i, j, North{}), has(i, j, East{}),
                     has(i, j, South{}), has(i, j, West{}))
  +stem = is_eq_dir(d, opposite(gone))
  +gives = gives_way(s, minor_of(i, j, d), stem)
  +given = Bool.and(has_give_way(c, s), Bool.not(gives))
  approach_of(d, has(i, j, d), half_cm(street), street, c, gives, given)

# The four approaches of a junction. One that has no street is still answered,
# so the list is the same shape everywhere and the renderer can walk it.
def approaches(+i: U32, +j: U32, +seed: U32) -> List<Approach>:
  [ approach_at(i, j, North{}, seed)
  , approach_at(i, j, East{}, seed)
  , approach_at(i, j, South{}, seed)
  , approach_at(i, j, West{}, seed)
  ]

# ---------------------------------------------------------------------------
# Reading the furniture back, so a law can state what a junction carries.
# ---------------------------------------------------------------------------

def mark_is(m: Mark, want: Mark) -> Bool:
  match m:
    case StopLine{}:
      match want:
        case StopLine{}:
          True{}
        case _:
          False{}
    case GiveWayLine{}:
      match want:
        case GiveWayLine{}:
          True{}
        case _:
          False{}
    case NoLine{}:
      match want:
        case NoLine{}:
          True{}
        case _:
          False{}

def post_is(p: Post, want: Post) -> Bool:
  match p:
    case PriorityWarning{}:
      match want:
        case PriorityWarning{}:
          True{}
        case _:
          False{}
    case GiveWaySign{}:
      match want:
        case GiveWaySign{}:
          True{}
        case _:
          False{}
    case StopSign{}:
      match want:
        case StopSign{}:
          True{}
        case _:
          False{}
    case NoSign{}:
      match want:
        case NoSign{}:
          True{}
        case _:
          False{}

# A street that is not there carries nothing, so it is skipped.
def every_mark(xs: List<Approach>, +want: Mark) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case +h <> t:
      match h:
        case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
          +ok = Bool.or(Bool.not(present), mark_is(mark, want))
          Bool.and(ok, every_mark(t, want))

def every_post(xs: List<Approach>, +want: Post) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case +h <> t:
      match h:
        case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
          +ok = Bool.or(Bool.not(present), post_is(post, want))
          Bool.and(ok, every_post(t, want))

def every_head(xs: List<Approach>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case +h <> t:
      match h:
        case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
          Bool.and(Bool.or(Bool.not(present), head), every_head(t))

def every_line_behind_the_kerb(xs: List<Approach>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case +h <> t:
      match h:
        case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
          +ok = Bool.or(Bool.not(present), U32.is_lt(half, line_cm))
          Bool.and(ok, every_line_behind_the_kerb(t))

def gives_of(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Bool:
  +gone = missing_of(has(i, j, North{}), has(i, j, East{}),
                     has(i, j, South{}), has(i, j, West{}))
  gives_way(shape(i, j, seed), minor_of(i, j, d), is_eq_dir(d, opposite(gone)))

def mark_at(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Mark:
  mark_of(control(i, j), gives_of(i, j, d, seed))

def post_in(a: Approach) -> Post:
  match a:
    case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
      post

def post_at(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Post:
  post_in(approach_at(i, j, d, seed))
