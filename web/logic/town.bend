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

# ===========================================================================
# The junction box
#
# A street stops short of the node it meets, and the ground between the stops
# is the junction. How far a kerb stops is the kerb return of Bina Marga
# 08/PBM/2024, Pedoman Perencanaan Teknis Geometrik Simpang: at least six
# metres in an urban junction, 4.5 to 7.5 m for passenger cars, 7.5 to 9 m
# where a collector crosses, 9 m or more on the ring, and one radius on all
# four corners. The seed moves the radius inside that band and never outside
# it, so a street that meets a wider one is always cut back past the wider
# one's kerb. That single number is what makes the pavement continuous through
# the corner, instead of a disc laid over it.
# ===========================================================================

def ring_here(+i: U32, +j: U32) -> Bool:
  Bool.or(Bool.or(U32.is_eq(i, 0), U32.is_eq(i, U32.sub(cols(), 1))),
          Bool.or(U32.is_eq(j, 0), U32.is_eq(j, U32.sub(rows(), 1))))

# Two local streets, a collector, or the ring.
def junction_rank(+i: U32, +j: U32) -> U32:
  Bool.pick(U32, ring_here(i, j), 2,
            Bool.pick(U32, Bool.or(major_col(i), major_row(j)), 1, 0))

def junction_radius_cm(+i: U32, +j: U32, +seed: U32) -> U32:
  +base = U32.add(600, U32.mul(150, junction_rank(i, j)))
  +band = U32.add(150, U32.mul(75, junction_rank(i, j)))
  U32.add(base, U32.mod(mix(U32.add(i, 31), U32.add(j, 977)), band))

def widest(a: Bool, ah: U32, b: Bool, bh: U32) -> U32:
  U32.max(Bool.pick(U32, a, ah, 0), Bool.pick(U32, b, bh, 0))

# The widest street whose kerb cuts this approach: the one across the node.
def cross_half(+i: U32, +j: U32, +d: Dir) -> U32:
  match d:
    case North{}:
      widest(has(i, j, East{}), half_cm(street_of(i, j, East{})),
             has(i, j, West{}), half_cm(street_of(i, j, West{})))
    case South{}:
      widest(has(i, j, East{}), half_cm(street_of(i, j, East{})),
             has(i, j, West{}), half_cm(street_of(i, j, West{})))
    case East{}:
      widest(has(i, j, North{}), half_cm(street_of(i, j, North{})),
             has(i, j, South{}), half_cm(street_of(i, j, South{})))
    case West{}:
      widest(has(i, j, North{}), half_cm(street_of(i, j, North{})),
             has(i, j, South{}), half_cm(street_of(i, j, South{})))

# How far from the node an approach's kerb stops.
def mouth_cm(+i: U32, +j: U32, +d: Dir, +seed: U32) -> U32:
  U32.add(cross_half(i, j, d), junction_radius_cm(i, j, seed))


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

# The line stands behind the junction box, not behind the approach's own
# carriageway: a driver on a local street meeting the ring must stop before the
# ring's near kerb, which is the widest street that reaches the node plus the
# kerb return. The crossing stands further back still. A local street with no
# line has no crossing.
def line_cm(+behind: U32) -> U32:
  U32.add(behind, 200)

def crossing_cm(control: Control, street: Street, +behind: U32) -> U32:
  match control:
    case Signal{}:
      U32.add(behind, 900)
    case Roundabout{}:
      0
    case Uncontrolled{}:
      match street:
        case Ring{}:
          U32.add(behind, 900)
        case Collector{}:
          U32.add(behind, 900)
        case Local{}:
          0

def approach_of(d: Dir, present: Bool, +half: U32, +behind: U32, street: Street, +c: Control,
                +gives: Bool, +given: Bool) -> Approach:
  Approach{d, present, half, mark_of(c, gives), line_cm(behind), crossing_cm(c, street, behind),
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
  approach_of(d, has(i, j, d), half_cm(street), mouth_cm(i, j, d, seed), street, c, gives, given)

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

# A line stands behind the box, which is the widest street across the approach
# plus its kerb return: the approach's own width says nothing about how far a
# driver on it has to go before the crossing carriageway begins.
def every_line_behind_the_box(xs: List<Approach>, +i: U32, +j: U32) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case +h <> t:
      match h:
        case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
          +ok = Bool.or(Bool.not(present), U32.is_lt(cross_half(i, j, d), line_cm))
          Bool.and(ok, every_line_behind_the_box(t, i, j))

def gives_of(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Bool:
  +gone = missing_of(has(i, j, North{}), has(i, j, East{}),
                     has(i, j, South{}), has(i, j, West{}))
  gives_way(shape(i, j, seed), minor_of(i, j, d), is_eq_dir(d, opposite(gone)))

def line_in(a: Approach) -> U32:
  match a:
    case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
      line_cm

def line_at(+i: U32, +j: U32, +d: Dir, +seed: U32) -> U32:
  line_in(approach_at(i, j, d, seed))

def mark_at(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Mark:
  mark_of(control(i, j), gives_of(i, j, d, seed))

def post_in(a: Approach) -> Post:
  match a:
    case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
      post

def post_at(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Post:
  post_in(approach_at(i, j, d, seed))

# ===========================================================================
# Blocks and lots
#
# A block is four frontages: one for each street that bounds it. A lot's front
# line is the street's own curve pushed back by the kerb and the pavement, so
# every building faces the road it stands on instead of a chord drawn between
# two junctions. Lots are cut by the fraction of the street they take, so a
# row of them tiles its frontage exactly, and the sides of a lot are square to
# the street because both come from the same two fractions.
#
# The same construction repeats inward: a second ring of lots faces the gang
# behind the first, and the block stops when the rings meet in the middle. That
# is the offset subdivision CityEngine documents and Vanegas et al. derive from
# the straight skeleton, kept to index arithmetic so a law can talk about it.
# ===========================================================================

# Integer square root by Newton's method, from above. Thirty-two steps reach
# the root of any thirty-two-bit number.
def root(fuel: Nat, +n: U32, +x: U32) -> U32:
  match fuel:
    case 0n:
      x
    case 1n+p:
      +next = U32.div(U32.add(x, U32.div(n, U32.max(x, 1))), 2)
      root(p, n, Bool.pick(U32, U32.is_le(x, next), x, next))

# Newton from the number itself, capped, converges inside twenty steps.
def sqrt(+n: U32) -> U32:
  root(20n, n, U32.min(n, 65535))

def length(a: Pt, b: Pt) -> U32:
  match a:
    case Pt{ax, az}:
      match b:
        case Pt{bx, bz}:
          +dx = U32.sub(bx, ax)
          +dz = U32.sub(bz, az)
          sqrt(U32.add(U32.mul(dx, dx), U32.mul(dz, dz)))

def mix_pt(p: Pt, q: Pt, +t: U32) -> Pt:
  match p:
    case Pt{px, pz}:
      match q:
        case Pt{qx, qz}:
          Pt{lerp(px, qx, t), lerp(pz, qz, t)}

# The block as a bilinear patch: a point is found by travelling `u` along the
# south edge and `v` from there to the north edge.
def quad_point(a: Pt, b: Pt, c: Pt, d: Pt, +u: U32, +v: U32) -> Pt:
  mix_pt(mix_pt(a, b, u), mix_pt(d, c, u), v)

def span_of(s: Signed) -> U32:
  match s:
    case Signed{size, down}:
      size

# A direction as a step of 1024, sign kept.
def unit(a: U32, b: U32, wide: U32) -> Signed:
  +d = gap_cm(a, b)
  Signed{U32.div(U32.mul(span_of(d), 1024), U32.max(wide, 1)), below(d)}

def push_along(base: U32, u: Signed, dist: U32) -> U32:
  match u:
    case Signed{size, down}:
      place(base, U32.div(U32.mul(size, dist), 1024), down)

type Frame is Data:
  Frame{origin: Pt, ux: Signed, uz: Signed, nx: Signed, nz: Signed}

# The block's own axes: along its row j street, and into the block.
def chord(ax: U32, az: U32, bx: U32, bz: U32) -> U32:
  +dx = U32.sub(bx, ax)
  +dz = U32.sub(bz, az)
  sqrt(U32.add(U32.mul(dx, dx), U32.mul(dz, dz)))

def inwards_x(ux: Signed, uz: Signed) -> Signed:
  match uz:
    case Signed{size, down}:
      Signed{size, Bool.not(down)}

def inwards_z(ux: Signed, uz: Signed) -> Signed:
  match ux:
    case Signed{size, down}:
      Signed{size, down}

def frame_from(a: Pt, b: Pt) -> Frame:
  match a:
    case Pt{+ax, +az}:
      match b:
        case Pt{+bx, +bz}:
          +wide = chord(ax, az, bx, bz)
          +ux = unit(ax, bx, wide)
          +uz = unit(az, bz, wide)
          Frame{Pt{ax, az}, ux, uz, inwards_x(ux, uz), inwards_z(ux, uz)}

def frame_of(+i: U32, +j: U32, +seed: U32) -> Frame:
  frame_from(site(i, j, seed), site(U32.add(i, 1), j, seed))

def negate(s: Signed) -> Signed:
  match s:
    case Signed{size, down}:
      Signed{size, Bool.not(down)}

# A block's south street and north street, which are rows j and j+1.
def south_half(+i: U32, +j: U32) -> U32:
  half_cm(street_of(i, j, East{}))

def north_half(+i: U32, +j: U32) -> U32:
  half_cm(street_of(i, U32.add(j, 1), East{}))

def pavement_cm() -> U32:
  150

def row_depth_cm() -> U32:
  1200

def gang_cm() -> U32:
  300

def block_depth(+i: U32, +j: U32, +seed: U32) -> U32:
  length(site(i, j, seed), site(i, U32.add(j, 1), seed))

def block_width(+i: U32, +j: U32, +seed: U32) -> U32:
  length(site(i, j, seed), site(U32.add(i, 1), j, seed))

# A block exists where both of the streets that bound it do. The river leaves
# a column of cells with no east street, and those are water, not blocks.
def block_exists(+i: U32, +j: U32) -> Bool:
  Bool.and(has(i, j, East{}), has(i, j, South{}))

# ---------------------------------------------------------------------------
# The four frontages of a block
#
# Side 0 is the street along row j, side 1 the street down column i + 1, side 2
# the street along row j + 1 and side 3 the street down column i. The block
# lies to one fixed side of each, and that side is the direction a lot is
# pushed to reach its own depth.
# ---------------------------------------------------------------------------

def side_i(+i: U32, +side: U32) -> U32:
  Bool.pick(U32, U32.is_eq(side, 1), U32.add(i, 1), i)

def side_j(+j: U32, +side: U32) -> U32:
  Bool.pick(U32, U32.is_eq(side, 2), U32.add(j, 1), j)

def side_dir(side: U32) -> Dir:
  Bool.pick(Dir, U32.is_eq(U32.mod(side, 2), 0), East{}, South{})

# The node at the far end of that frontage.
def far_i(+i: U32, +side: U32) -> U32:
  Bool.pick(U32, U32.is_eq(side, 3), i, U32.add(i, 1))

def far_j(+j: U32, +side: U32) -> U32:
  Bool.pick(U32, U32.is_eq(side, 0), j, U32.add(j, 1))

# A frontage only exists where its street does. The river leaves a column with
# no street, and the edge of the town leaves the blocks beside it without one,
# so a side that has no street carries no lot.
def side_open(+i: U32, +j: U32, +side: U32) -> Bool:
  has(side_i(i, side), side_j(j, side), side_dir(side))

def side_len(+i: U32, +j: U32, +side: U32, +seed: U32) -> U32:
  length(site(side_i(i, side), side_j(j, side), seed),
         site(far_i(i, side), far_j(j, side), seed))

def inward_x(f: Frame, +side: U32) -> Signed:
  match f:
    case Frame{origin, +ux, +uz, +nx, +nz}:
      Bool.pick(Signed, U32.is_lt(side, 2),
                Bool.pick(Signed, U32.is_eq(side, 0), nx, negate(ux)),
                Bool.pick(Signed, U32.is_eq(side, 2), negate(nx), ux))

def inward_z(f: Frame, +side: U32) -> Signed:
  match f:
    case Frame{origin, +ux, +uz, +nx, +nz}:
      Bool.pick(Signed, U32.is_lt(side, 2),
                Bool.pick(Signed, U32.is_eq(side, 0), nz, negate(uz)),
                Bool.pick(Signed, U32.is_eq(side, 2), negate(nz), uz))

def mid_pt(a: Pt, b: Pt) -> Pt:
  match a:
    case Pt{ax, az}:
      match b:
        case Pt{bx, bz}:
          Pt{U32.div(U32.add(ax, bx), 2), U32.div(U32.add(az, bz), 2)}

# A point pushed `reach` centimetres into the block from the side it is on.
def push_in(p: Pt, +f: Frame, +side: U32, +reach: U32) -> Pt:
  match p:
    case Pt{px, pz}:
      Pt{push_along(px, inward_x(f, side), reach), push_along(pz, inward_z(f, side), reach)}

# How far a frontage line stands from its street's centre line.
def kerb_cm(+i: U32, +j: U32, +side: U32) -> U32:
  U32.add(half_cm(street_of(side_i(i, side), side_j(j, side), side_dir(side))), pavement_cm())

# A point on a frontage line: a fraction of the street, in thousand-and-
# twenty-fourths, pushed back from the kerb by `back` centimetres.
def front_pt(+i: U32, +j: U32, +side: U32, +t: U32, +back: U32, +seed: U32) -> Pt:
  push_in(at(curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed), t),
          frame_of(i, j, seed), side, U32.add(kerb_cm(i, j, side), back))

# Where the frontage starts and ends: the two mouths of its street, as
# fractions of it.
def near_t(+i: U32, +j: U32, +side: U32, +seed: U32) -> U32:
  +m = mouth_cm(side_i(i, side), side_j(j, side), side_dir(side), seed)
  U32.min(U32.div(U32.mul(m, 1024), U32.max(side_len(i, j, side, seed), 1)), 1024)

def far_t(+i: U32, +j: U32, +side: U32, +seed: U32) -> U32:
  +m = mouth_cm(far_i(i, side), far_j(j, side), opposite(side_dir(side)), seed)
  U32.min(U32.div(U32.mul(m, 1024), U32.max(side_len(i, j, side, seed), 1)), 1024)

# The span between the two mouths. A street shorter than its own mouths has no
# frontage at all, and says so instead of wrapping round to a huge one.
def span_t(+i: U32, +j: U32, +side: U32, +seed: U32) -> U32:
  +taken = U32.add(near_t(i, j, side, seed), far_t(i, j, side, seed))
  Bool.pick(U32, U32.is_lt(taken, 1024), U32.sub(1024, taken), 0)

# The frontage a block can build on, in centimetres.
def frontage_cm(+i: U32, +j: U32, +side: U32, +seed: U32) -> U32:
  U32.div(U32.mul(span_t(i, j, side, seed), side_len(i, j, side, seed)), 1024)

# A frontage lot is a shop-house six metres across; the rings behind take
# kampung plots eleven metres across, which is what a yard and a terrace need.
# The count follows the frontage, so a lot is never narrower than its pitch —
# `lots` lots share the frontage exactly, and `lots` is the frontage divided by
# the pitch, so the share cannot fall below the pitch itself.
def pitch_of(ring: U32) -> U32:
  Bool.pick(U32, U32.is_eq(ring, 0), 600, 1100)


def lots_where(on: Bool, +i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  match on:
    case True{}:
      U32.min(U32.div(frontage_cm(i, j, side, seed), pitch_of(ring)), 12)
    case False{}:
      0

def lots_on(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  lots_where(side_open(i, j, side), i, j, side, ring, seed)

def lot_width(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  U32.div(frontage_cm(i, j, side, seed), U32.max(lots_on(i, j, side, ring, seed), 1))

# The fraction of the street where lot t of a frontage starts.
def lot_edge_t(+i: U32, +j: U32, +side: U32, +ring: U32, +t: U32, +seed: U32) -> U32:
  U32.add(near_t(i, j, side, seed),
          U32.div(U32.mul(U32.mul(t, span_t(i, j, side, seed)), 1),
                  U32.max(lots_on(i, j, side, ring, seed), 1)))

# How many rings of lots fit between two opposite frontages before they meet.
def rings_in(+i: U32, +j: U32, +seed: U32) -> U32:
  +room = U32.sub(U32.min(block_depth(i, j, seed), block_width(i, j, seed)),
                  U32.mul(2, U32.add(half_cm(Ring{}), pavement_cm())))
  U32.min(U32.max(U32.div(room, U32.mul(2, U32.add(row_depth_cm(), gang_cm()))), 1), 3)

type LotKind is Data:
  Ruko{}
  Warung{}
  House{}
  Kos{}
  Petak{}
  Filler{}

# What a kind needs of its lot: the frontage it cannot be narrower than, and
# the depth it takes out of its ring. The renderer draws every building to
# exactly its lot, so these two numbers are the whole of the non-overlap
# argument — a lot is cut at least `min` wide, and no kind is deeper than a
# ring.
def kind_min_cm(k: LotKind) -> U32:
  match k:
    case Ruko{}:
      450
    case Warung{}:
      350
    case House{}:
      700
    case Kos{}:
      520
    case Petak{}:
      340
    case Filler{}:
      500

def kind_depth_cm(k: LotKind) -> U32:
  match k:
    case Ruko{}:
      1200
    case Warung{}:
      500
    case House{}:
      1200
    case Kos{}:
      1000
    case Petak{}:
      800
    case Filler{}:
      1000

def kind_fits(k: LotKind, w: U32) -> Bool:
  U32.is_le(kind_min_cm(k), w)

# The frontage ring is shop-houses and the rings behind are kampung plots. A
# kind is chosen only from those that fit the lot it will stand in, and the
# narrowest kind of its ring is the fallback, so no roll can ask for a building
# wider than the ground under it.
def kind_pick(frontage: Bool, +w: U32, +roll: U32) -> LotKind:
  Bool.pick(LotKind, frontage,
            Bool.pick(LotKind, U32.is_lt(roll, 78),
                      Bool.pick(LotKind, kind_fits(Ruko{}, w), Ruko{}, Warung{}),
                      Warung{}),
            Bool.pick(LotKind, U32.is_lt(roll, 42),
                      Bool.pick(LotKind, kind_fits(House{}, w), House{}, Petak{}),
                      Bool.pick(LotKind, U32.is_lt(roll, 66),
                                Bool.pick(LotKind, kind_fits(Kos{}, w), Kos{}, Petak{}),
                                Petak{})))

def kind_of(+i: U32, +j: U32, +side: U32, +ring: U32, +t: U32, +seed: U32) -> LotKind:
  +roll = U32.mod(mix(U32.add(t, U32.mul(ring, 31)), U32.add(seed, U32.mul(side, 7))), 100)
  kind_pick(U32.is_eq(ring, 0), lot_width(i, j, side, ring, seed), roll)

# Every roll the picker can see, at one width: the law that a kind fits the lot
# it is chosen for, checked over the whole roll space rather than sampled.
def every_roll_fits(fuel: Nat, +roll: U32, +frontage: Bool, +w: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      Bool.and(kind_fits(kind_pick(frontage, w, roll), w),
               every_roll_fits(p, U32.add(roll, 1), frontage, w))

type Lot is Data:
  Lot{x: U32, z: U32, fx: Signed, fz: Signed, w: U32, d: U32, kind: LotKind}

# An even ring faces the street it stands on; an odd ring faces the gang behind
# the ring in front of it.
def outward(ring: U32) -> Bool:
  U32.is_eq(U32.mod(ring, 2), 0)

def face_x(+f: Frame, +side: U32, +ring: U32) -> Signed:
  Bool.pick(Signed, outward(ring), negate(inward_x(f, side)), inward_x(f, side))

def face_z(+f: Frame, +side: U32, +ring: U32) -> Signed:
  Bool.pick(Signed, outward(ring), negate(inward_z(f, side)), inward_z(f, side))

# One lot: its footprint centre, the way its front looks, its width and depth.
def lot_at(+i: U32, +j: U32, +side: U32, +ring: U32, +t: U32, +seed: U32) -> Lot:
  +kind = kind_of(i, j, side, ring, t, seed)
  +depth = kind_depth_cm(kind)
  +back = U32.mul(ring, U32.add(row_depth_cm(), gang_cm()))
  +a = front_pt(i, j, side, lot_edge_t(i, j, side, ring, t, seed), back, seed)
  +b = front_pt(i, j, side, lot_edge_t(i, j, side, ring, U32.add(t, 1), seed), back, seed)
  +w = length(a, b)
  +mid = mid_pt(a, b)
  +f = frame_of(i, j, seed)
  +reach = U32.add(kerb_cm(i, j, side), U32.add(back, U32.div(depth, 2)))
  +here = push_in(mid, f, side, reach)
  Lot{pt_x(here), pt_z(here), face_x(f, side, ring), face_z(f, side, ring), w, depth, kind}

# ---------------------------------------------------------------------------
# The core of a block
#
# The rings stop where the block runs out of depth, and what is left in the
# middle is filled by a grid of lots that face nothing in particular: a terrace
# or a kos with no street of its own. The grid is cut from the block's own
# frame, because the core has no kerb to follow, and every cell is one lot.
# ---------------------------------------------------------------------------

def core_in(+i: U32, +j: U32, +side: U32, +seed: U32) -> U32:
  U32.add(kerb_cm(i, j, side),
          U32.mul(rings_in(i, j, seed), U32.add(row_depth_cm(), gang_cm())))

# The node a core corner stands at: the pair of sides that meet there names it.
def corner_i(+i: U32, +a: U32, +b: U32) -> U32:
  Bool.pick(U32, Bool.or(U32.is_eq(a, 3), U32.is_eq(b, 3)), i, U32.add(i, 1))

def corner_j(+j: U32, +a: U32, +b: U32) -> U32:
  Bool.pick(U32, Bool.or(U32.is_eq(a, 0), U32.is_eq(b, 0)), j, U32.add(j, 1))

# One corner of the core: the block's own node there, pushed in from both
# streets that meet at it.
def core_corner(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Pt:
  push_in(push_in(site(corner_i(i, a, b), corner_j(j, a, b), seed), frame_of(i, j, seed), a,
                  core_in(i, j, a, seed)),
          frame_of(i, j, seed), b, core_in(i, j, b, seed))

def core_widest(+i: U32, +j: U32, +seed: U32) -> U32:
  U32.max(U32.max(core_in(i, j, 0, seed), core_in(i, j, 1, seed)),
          U32.max(core_in(i, j, 2, seed), core_in(i, j, 3, seed)))

# The core only exists where all four streets do and the rings leave room for
# it: it is the middle of a block, and a block with a missing side, or one too
# narrow for its own frontages, has no middle to speak of.
def core_ready(+i: U32, +j: U32, +seed: U32) -> Bool:
  Bool.and(side_open(i, j, 0), Bool.and(side_open(i, j, 1),
  Bool.and(side_open(i, j, 2), Bool.and(side_open(i, j, 3),
           U32.is_lt(U32.mul(2, core_widest(i, j, seed)),
                     U32.min(block_depth(i, j, seed), block_width(i, j, seed)))))))

def core_at(+i: U32, +j: U32, +u: U32, +v: U32, +seed: U32) -> Pt:
  quad_point(core_corner(i, j, 3, 0, seed), core_corner(i, j, 0, 1, seed),
             core_corner(i, j, 1, 2, seed), core_corner(i, j, 2, 3, seed), u, v)

def core_width(+i: U32, +j: U32, +seed: U32) -> U32:
  length(core_corner(i, j, 3, 0, seed), core_corner(i, j, 0, 1, seed))

def core_depth(+i: U32, +j: U32, +seed: U32) -> U32:
  length(core_corner(i, j, 3, 0, seed), core_corner(i, j, 2, 3, seed))

def core_lots_w(+i: U32, +j: U32, +seed: U32) -> U32:
  Bool.pick(U32, core_ready(i, j, seed),
            U32.min(U32.max(U32.div(core_width(i, j, seed), 1100), 1), 4), 0)

def core_lots_d(+i: U32, +j: U32, +seed: U32) -> U32:
  Bool.pick(U32, core_ready(i, j, seed),
            U32.min(U32.max(U32.div(core_depth(i, j, seed), 1100), 1), 4), 0)

# A core lot has no street to face, so it takes a filler: a terrace with a
# window on every side instead of one front and three blank walls.
def core_kind(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> LotKind:
  Filler{}

def core_lot_width(+i: U32, +j: U32, +seed: U32) -> U32:
  U32.div(core_width(i, j, seed), core_lots_w(i, j, seed))

def core_lot_at(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Lot:
  +nw = core_lots_w(i, j, seed)
  +nd = core_lots_d(i, j, seed)
  +u = U32.div(U32.mul(U32.add(U32.mul(a, 2), 1), 1024), U32.mul(nw, 2))
  +v = U32.div(U32.mul(U32.add(U32.mul(b, 2), 1), 1024), U32.mul(nd, 2))
  +here = core_at(i, j, u, v, seed)
  +kind = core_kind(i, j, a, b, seed)
  +f = frame_of(i, j, seed)
  Lot{pt_x(here), pt_z(here), face_x(f, 3, 0), face_z(f, 3, 0),
      core_lot_width(i, j, seed), kind_depth_cm(kind), kind}

# ---------------------------------------------------------------------------
# Reading the lots back, so a law can walk a block.
# ---------------------------------------------------------------------------

def lot_inside(l: Lot) -> Bool:
  match l:
    case Lot{+x, +z, fx, fz, w, d, kind}:
      Bool.and(U32.is_lt(0, x), Bool.and(U32.is_lt(x, 90000),
      Bool.and(U32.is_lt(0, z), U32.is_lt(z, 90000))))

# The first and last lot of each of the four frontages, walked by counting
# sides up. Between them they carry the ends of every row, which is where a lot
# could leave the town.
def sides_inside(fuel: Nat, +side: U32, +i: U32, +j: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +lots = lots_on(i, j, side, 0, seed)
      +ok = Bool.or(U32.is_eq(lots, 0),
                    Bool.and(lot_inside(lot_at(i, j, side, 0, 0, seed)),
                             lot_inside(lot_at(i, j, side, 0, U32.sub(lots, 1), seed))))
      Bool.and(ok, sides_inside(p, U32.add(side, 1), i, j, seed))

# Every lot of a block fits the kind that stands in it: the kind is never wider
# than the lot it was chosen for, and never deeper than a ring.
def lots_fit(fuel: Nat, +t: U32, +side: U32, +ring: U32, +i: U32, +j: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +live = U32.is_lt(t, lots_on(i, j, side, ring, seed))
      +kind = kind_of(i, j, side, ring, t, seed)
      +ok = Bool.or(Bool.not(live),
                    Bool.and(U32.is_le(kind_min_cm(kind), lot_width(i, j, side, ring, seed)),
                             U32.is_le(kind_depth_cm(kind), row_depth_cm())))
      Bool.and(ok, lots_fit(p, U32.add(t, 1), side, ring, i, j, seed))

# The frame of an approach: its own street's chord from the node, and the
# perpendicular to it, which is the left of travel. A mouth is square to the
# street it belongs to, not to the block beside it, so each approach brings its
# own frame.
def approach_frame(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Frame:
  frame_from(site(i, j, seed), end_of(i, j, d, seed))

def mouth_at(f: Frame, +m: U32, +h: U32, +left: Bool) -> Pt:
  match f:
    case Frame{origin, +ux, +uz, +nx, +nz}:
      match origin:
        case Pt{ox, oz}:
          +sx = Bool.pick(Signed, left, negate(nx), nx)
          +sz = Bool.pick(Signed, left, negate(nz), nz)
          Pt{push_along(push_along(ox, ux, m), sx, h), push_along(push_along(oz, uz, m), sz, h)}

# One end of an approach's mouth: the point where its kerb stops.
def mouth_side(+i: U32, +j: U32, +d: Dir, +left: Bool, +seed: U32) -> Pt:
  mouth_at(approach_frame(i, j, d, seed), mouth_cm(i, j, d, seed),
           half_cm(street_of(i, j, d)), left)

def mouth_mid(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Pt:
  mouth_at(approach_frame(i, j, d, seed), mouth_cm(i, j, d, seed), 0, True{})

def corner_in(here: Pt, own: Frame, side: Frame, +h_side: U32, +h_own: U32) -> Pt:
  match here:
    case Pt{ox, oz}:
      match own:
        case Frame{origin, +ux, +uz, nx, nz}:
          match side:
            case Frame{origin2, +sx, +sz, nx2, nz2}:
              Pt{push_along(push_along(ox, ux, h_side), sx, h_own),
                 push_along(push_along(oz, uz, h_side), sz, h_own)}

# Where the two kerbs of a corner would meet if the return were square: the
# control point of the fillet that rounds it. It is reached by taking b's half
# along a and a's half along b, so the corner is the same point from either
# side of it.
def corner_between(+i: U32, +j: U32, +a: Dir, +b: Dir, +seed: U32) -> Pt:
  corner_in(site(i, j, seed), approach_frame(i, j, a, seed), approach_frame(i, j, b, seed),
            half_cm(street_of(i, j, b)), half_cm(street_of(i, j, a)))

def corner_pt(+i: U32, +j: U32, +d: Dir, +seed: U32) -> Pt:
  corner_between(i, j, d, left_of(d), seed)
