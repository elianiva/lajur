# lajur — the town: a warped lattice of streets, its junctions and their duties.
#
# Six columns by five rows of junctions, a hundred and forty metres apart. A
# smooth two-dimensional wave moves every node, and that wave is the only source
# of curvature in the town: its amplitude, its cell and the pitch decide every
# radius in it, so PROOF.bend can bound the town's tightest bend from three
# numbers instead of sampling geometry.
#
# The 140 m pitch is the RT scale: 30 to 50 houses around a gang, which is what
# SNI 03-1733-2004 counts as one neighbourhood unit. The four-figure arterial
# junction density of an Indonesian city (Makassar, the densest in the ASEAN
# sample, 160.8 per km²) comes from the gang mesh, not from arterial crossings,
# so the arterial lattice is coarse and the gangs live inside the blocks. A
# street returns to its dense self only as a pavement and a lane, and the player
# drives the coarse tier.
#
# Index decides class. Every second column and row is a collector, and the
# boundary is the ring. That gives 280 m between collectors and 140 m between
# local streets: the three tiers SNI's road classes describe, at their own
# spacing. Geometry decides the junction's shape, because a T on a bend is a
# skew T (Pasal 113 ayat (1) huruf d) and a T on a straight is a perpendicular T
# (huruf e). The field makes both, so the curvature is the curriculum and not
# the decoration.
import Base

# ===========================================================================
# The lattice
# ===========================================================================

# Junction count on each axis. Five blocks one way, four the other.
def cols() -> U32:
  6

def rows() -> U32:
  5

# Centre to centre, in centimetres. One RT: the houses that share a gang.
def pitch_cm() -> U32:
  14000

# The first node sits this far from the town's edge, so the outermost bend of
# the field and the curve handles beyond it stay inside the canvas, and no
# coordinate can wrap below zero.
def margin_cm() -> U32:
  8000

# The field moves a node by at most this much, each way.
def amp_cm() -> U32:
  4000

# The field repeats over this many blocks. Longer is a sweep, shorter is a
# slalom; six blocks at forty metres is a street that visibly bends once across the
# view, at a 370 m radius: an arterial sweep, not a slalom.
def cells() -> U32:
  6

# The town the game ships.
def seed_of_town() -> U32:
  20261024

# A collector runs along every second column and row, 280 m apart; the edge is
# the ring. Behind the four frontage rows sits the block's own gang, which no
# junction indexes: a lane, not a street.
def major_col(i: U32) -> Bool:
  U32.is_eq(U32.mod(i, 2), 0)

def major_row(j: U32) -> Bool:
  U32.is_eq(U32.mod(j, 2), 0)

# The river runs between column three and column four, and only the two bridges
# cross it. That is the town's one edge, and every bridge approach is a T
# junction.
def river_gap() -> U32:
  3

def bridge(+j: U32) -> Bool:
  Bool.or(U32.is_eq(j, 1), U32.is_eq(j, 3))

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
  1300

def gang_cm() -> U32:
  200

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

# A step of 1024 along the path from a to b.
def unit_of(a: Pt, b: Pt) -> Vec:
  match a:
    case Pt{+ax, +az}:
      match b:
        case Pt{+bx, +bz}:
          +wide = length(a, b)
          Vec{unit(ax, bx, wide), unit(az, bz, wide)}

def negate_vec(v: Vec) -> Vec:
  match v:
    case Vec{ux, uz}:
      Vec{negate(ux), negate(uz)}

# The normal that points into the block, from the way the street runs. Sides 0
# and 1 run with the block's winding, so the left of travel is the block; sides
# 2 and 3 run against it, so the left of travel is the street.
def inward_of(v: Vec, +side: U32) -> Vec:
  match v:
    case Vec{+ux, +uz}:
      +left: Vec = Vec{Signed{span_of(uz), Bool.not(below(uz))}, Signed{span_of(ux), below(ux)}}
      Bool.pick(Vec, U32.is_lt(side, 2), left, negate_vec(left))

# The street's frame at a fraction of its length: where it is, which way it
# runs, and which way the block lies. Every lot is drawn in one of these, so a
# row follows the street instead of the block's chord.
def frame_join(origin: Pt, v: Vec, n: Vec) -> Frame:
  match v:
    case Vec{ux, uz}:
      match n:
        case Vec{nx, nz}:
          Frame{origin, ux, uz, nx, nz}

def frame_on(+c: Curve, +side: U32, +t: U32) -> Frame:
  +lo = at(c, U32.sub(t, U32.min(t, 12)))
  +hi = at(c, U32.min(U32.add(t, 12), 1024))
  +v = unit_of(lo, hi)
  frame_join(at(c, t), v, inward_of(v, side))

def frame_at(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Frame:
  frame_on(curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed), side, t)

# A point `reach` centimetres from `p`, along the frame's normal.
def advance(p: Pt, +f: Frame, +reach: U32) -> Pt:
  match p:
    case Pt{px, pz}:
      match f:
        case Frame{origin, ux, uz, nx, nz}:
          Pt{push_along(px, nx, reach), push_along(pz, nz, reach)}

# A point on a frontage line: a fraction of the street, in thousand-and-
# twenty-fourths, pushed into the block past the kerb and `back` centimetres
# further. The push follows the street's own normal, so the line is a frontage
# and not a chord.
def front_pt(+i: U32, +j: U32, +side: U32, +t: U32, +back: U32, +seed: U32) -> Pt:
  +c = curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed)
  advance(at(c, t), frame_on(c, side, t), U32.add(kerb_cm(i, j, side), back))

# How far inside the block a ring stands.
def back_cm(ring: U32) -> U32:
  U32.mul(ring, U32.add(row_depth_cm(), gang_cm()))

# The gap a row leaves between two lots: a yard, a wall, a drain. It is also the
# room that keeps two lots apart when the street bends under them.
def lot_gap_cm() -> U32:
  10

# The town is not one recipe repeated. A block is a court (two rows round a
# kampung grid), a kit (one row round a bigger grid) or a yard (one row with the
# middle left open, the alun-alun a kelurahan keeps). Which one is a roll of the
# block's own seed, so two blocks side by side differ the way two kampungs do,
# while the shape each takes is still a fixed rule.
#
# Most blocks are kits. A second row costs more than it builds: at the sharpest
# corner a row has to stand 1.7 bands — fifty metres — back from the corner, so
# the row behind the gang survives as a stub of two or three lots and the grid
# it squeezes out of the middle is a quarter smaller. One row and a wider grid
# builds more of the block, and the grid is where the block's variety lives.
def block_roll(+i: U32, +j: U32, +seed: U32) -> U32:
  U32.mod(mix(U32.add(i, 11), U32.add(j, 7)), 100)

def block_yard(+i: U32, +j: U32, +seed: U32) -> Bool:
  U32.is_lt(block_roll(i, j, seed), 12)

def block_kit(+i: U32, +j: U32, +seed: U32) -> Bool:
  U32.is_lt(block_roll(i, j, seed), 88)

# How many rings of lots fit between two opposite frontages before they meet.
def rings_in(+i: U32, +j: U32, +seed: U32) -> U32:
  +room = U32.sub(U32.min(block_depth(i, j, seed), block_width(i, j, seed)),
                  U32.mul(2, U32.add(half_cm(Ring{}), pavement_cm())))
  +fits = U32.min(U32.max(U32.div(room, U32.mul(2, U32.add(row_depth_cm(), gang_cm()))), 1), 2)
  +wanted = Bool.pick(U32, Bool.or(block_kit(i, j, seed), block_yard(i, j, seed)), 1, 2)
  U32.max(U32.min(wanted, fits), 1)

# How far from a corner a ring's row turns in: the junction box, or the mitre
# of the ring inside the block, whichever is further.
#
# The mitre is a fact about offset subdivisions. A band `d` deep that stands on
# one street runs into a band `d` deep on the street it meets, and the two bands
# overlap in a parallelogram that reaches past the corner. A row stops clear of
# the other side's band when it stops short of the corner by
#
#   (d + d.cos(theta)) / sin(theta)  =  d.cot(theta/2)
#
# theta being the angle the two frontage lines make. At square that is d, and at
# the sharpest corner the field draws — sixty degrees, which a law below holds
# every one of them to — it is 1.75.d. So the mitre is not one number for the
# whole town: it is the corner's own angle, taken from the two chords that meet
# there, and the field's sharpest corner is a law rather than a multiplier.
#
# The cut is the ring's own whole band, junction box and pavement included,
# because that is what the other row has to clear. The last twentieth is for
# the curve: the chords meet a degree or two squarer than the frontage lines
# they carry.
def corner_margin_milli() -> U32:
  1060

# The node a block's corner stands on, counted round the block from its south
# west node.
def corner_i(+i: U32, +c: U32) -> U32:
  Bool.pick(U32, Bool.or(U32.is_eq(c, 1), U32.is_eq(c, 2)), U32.add(i, 1), i)

def corner_j(+j: U32, +c: U32) -> U32:
  Bool.pick(U32, U32.is_le(2, c), U32.add(j, 1), j)

# The magnitude of a wrapped difference, sign taken from the top bit.
def mag_of(+x: U32) -> U32:
  Bool.pick(U32, U32.is_gt(x, 2147483647), U32.sub(0, x), x)

# cot(theta / 2) at a block corner, in thousandths, from the two chords that
# meet there: (1 + cos) / sin, with cos and sin taken as the dot and cross of
# those chords over the product of their lengths. A chord pair that meets at
# nothing in particular would divide by zero, so the cross is floored at a
# thousandth of a radian's worth.
def corner_cot_milli(+i: U32, +j: U32, +c: U32, +seed: U32) -> U32:
  +back = U32.mod(U32.add(c, 3), 4)
  +ahead = U32.mod(U32.add(c, 1), 4)
  +o = site(corner_i(i, c), corner_j(j, c), seed)
  +a = site(corner_i(i, back), corner_j(j, back), seed)
  +b = site(corner_i(i, ahead), corner_j(j, ahead), seed)
  +ux = U32.sub(pt_x(a), pt_x(o))
  +uz = U32.sub(pt_z(a), pt_z(o))
  +vx = U32.sub(pt_x(b), pt_x(o))
  +vz = U32.sub(pt_z(b), pt_z(o))
  +cross = U32.max(mag_of(U32.sub(U32.mul(ux, vz), U32.mul(uz, vx))), 1)
  +dot = mag_of(U32.add(U32.mul(ux, vx), U32.mul(uz, vz)))
  +den = U32.mul(length(o, a), length(o, b))
  U32.min(U32.div(U32.add(den, dot), U32.max(U32.div(cross, 1000), 1)), 3000)

# How deep one side's band of a ring stands from its street's centre line.
def band_cm(+i: U32, +j: U32, +side: U32, +ring: U32) -> U32:
  U32.add(kerb_cm(i, j, side), U32.add(back_cm(ring), row_depth_cm()))

def mitre_cut_cm(+i: U32, +j: U32, +side: U32, +corner: U32, +ring: U32, +seed: U32) -> U32:
  +spread = U32.div(U32.mul(corner_cot_milli(i, j, corner, seed), corner_margin_milli()), 1000)
  U32.div(U32.mul(band_cm(i, j, side, ring), spread), 1000)

def near_cut_cm(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  U32.max(mouth_cm(side_i(i, side), side_j(j, side), side_dir(side), seed),
          mitre_cut_cm(i, j, side, side, ring, seed))

def far_cut_cm(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  U32.max(mouth_cm(far_i(i, side), far_j(j, side), opposite(side_dir(side)), seed),
          mitre_cut_cm(i, j, side, U32.mod(U32.add(side, 1), 4), ring, seed))

# Where the row starts and ends: those two cuts, laid on the ground.
#
# A curve's parameter is not its length. Between two nodes the handle a sixth
# of the way past each end makes the parameter run as much as a third slower
# than the chord, so a cut taken as a share of `side_len` lands short of the
# corner it means to clear — ten metres short on a fifty-metre cut. So the cut
# is found on the street instead: the point whose distance from the node is the
# cut, squared on both sides so nothing here takes a root, and six steps of a
# thousand-and-twenty-fourth, which leave the row within a metre of where it
# belongs.
#
# The point is the street's own centre line rather than the frontage line, and
# the frontage stands a kerb away from it, so the row lands a few per cent
# further out than the cut asks. That is the direction a mitre should err in.
def cut_step(fuel: Nat, +c: Curve, +o: Pt, +far: Bool, +cm: U32, +lo: U32, +hi: U32) -> U32:
  match fuel:
    case 0n:
      lo
    case 1n+p:
      +mid = U32.div(U32.add(lo, hi), 2)
      +t = Bool.pick(U32, far, U32.sub(1024, mid), mid)
      +q = at(c, t)
      +dx = U32.sub(pt_x(q), pt_x(o))
      +dz = U32.sub(pt_z(q), pt_z(o))
      +short = U32.is_le(U32.mul(cm, cm), U32.add(U32.mul(dx, dx), U32.mul(dz, dz)))
      cut_step(p, c, o, far, cm, Bool.pick(U32, short, lo, mid), Bool.pick(U32, short, mid, hi))

def cut_from(+i: U32, +j: U32, +side: U32, +far: Bool, +cm: U32, +seed: U32) -> U32:
  +c = curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed)
  +o = Bool.pick(Pt, far,
                 site(far_i(i, side), far_j(j, side), seed),
                 site(side_i(i, side), side_j(j, side), seed))
  cut_step(6n, c, o, far, cm, 0, 1024)

def near_t(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  cut_from(i, j, side, False{}, near_cut_cm(i, j, side, ring, seed), seed)

def far_t(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  cut_from(i, j, side, True{}, far_cut_cm(i, j, side, ring, seed), seed)

# The span between the two cuts. A street shorter than its own cuts has no
# frontage at all, and says so instead of wrapping round to a huge one.
def span_t(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  +taken = U32.add(near_t(i, j, side, ring, seed), far_t(i, j, side, ring, seed))
  Bool.pick(U32, U32.is_lt(taken, 1024), U32.sub(1024, taken), 0)

# The frontage a block can build on, in centimetres.
def frontage_cm(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  U32.div(U32.mul(span_t(i, j, side, ring, seed), side_len(i, j, side, seed)), 1024)

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
      U32.min(U32.div(frontage_cm(i, j, side, ring, seed),
                      U32.add(pitch_of(ring), lot_gap_cm())), 24)
    case False{}:
      0

def lots_on(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  lots_where(side_open(i, j, side), i, j, side, ring, seed)

# The share of the frontage a lot takes, less the gap it leaves.
def lot_width(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  +lots = lots_on(i, j, side, ring, seed)
  +share = U32.div(frontage_cm(i, j, side, ring, seed), U32.max(lots, 1))
  Bool.pick(U32, U32.is_eq(lots, 0), 0, U32.sub(share, U32.min(share, lot_gap_cm())))

# The fraction of the street where lot t of a frontage starts.
def lot_edge_t(+i: U32, +j: U32, +side: U32, +ring: U32, +t: U32, +seed: U32) -> U32:
  U32.add(near_t(i, j, side, ring, seed),
          U32.div(U32.mul(t, span_t(i, j, side, ring, seed)),
                  U32.max(lots_on(i, j, side, ring, seed), 1)))

type LotKind is Data:
  Ruko{}
  Warung{}
  House{}
  Kos{}
  Petak{}
  Filler{}
  Minimarket{}
  Bengkel{}
  Gudang{}

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
    case Minimarket{}:
      800
    case Bengkel{}:
      800
    case Gudang{}:
      900

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
    case Minimarket{}:
      1200
    case Bengkel{}:
      1100
    case Gudang{}:
      1200

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

# A lot is a cell of its band, not a rectangle: four corners, the front two on
# the frontage line and the back two `depth` behind them. A cell tiles its band
# exactly — the edge it shares with the next lot is the same radial line for
# both — so a row can follow a bent street without a gap and without a clash,
# and the back edge may be shorter than the front, which is the trapezoid an
# offset subdivision gives at a corner. `w` is the front edge, the width a kind
# is chosen against; `x, z` is the middle of the four corners.
type Lot is Data:
  Lot{x: U32, z: U32, fx: Signed, fz: Signed, w: U32, d: U32, kind: LotKind,
      ax: U32, az: U32, bx: U32, bz: U32, cx: U32, cz: U32, dx: U32, dz: U32}

# An even ring faces the street it stands on; an odd ring faces the gang behind
# the ring in front of it.
def outward(ring: U32) -> Bool:
  U32.is_eq(U32.mod(ring, 2), 0)

def lot_face(f: Frame, +ring: U32) -> Vec:
  match f:
    case Frame{origin, ux, uz, nx, nz}:
      +in: Vec = Vec{nx, nz}
      Bool.pick(Vec, outward(ring), negate_vec(in), in)

def lot_of(+x: U32, +z: U32, +w: U32, +d: U32, +kind: LotKind, face: Vec, +a: Pt, +b: Pt, +c: Pt, +e: Pt) -> Lot:
  match face:
    case Vec{fx, fz}:
      Lot{x, z, fx, fz, w, d, kind,
          pt_x(a), pt_z(a), pt_x(b), pt_z(b), pt_x(c), pt_z(c), pt_x(e), pt_z(e)}

# One lot: its footprint centre, the way its front looks, its width and depth.
# The lot is a rectangle on its own tangent, its front edge `w` wide and square
# to the street at its middle, and it stands `depth` deep from the frontage
# line. Two lots of a row are therefore one gap apart along the street and
# nothing else, whatever their depths.
def lot_at(+i: U32, +j: U32, +side: U32, +ring: U32, +t: U32, +seed: U32) -> Lot:
  +kind = kind_of(i, j, side, ring, t, seed)
  +depth = kind_depth_cm(kind)
  +t0 = lot_edge_t(i, j, side, ring, t, seed)
  +t1 = lot_edge_t(i, j, side, ring, U32.add(t, 1), seed)
  +mid = U32.div(U32.add(t0, t1), 2)
  +c = curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed)
  +f = frame_on(c, side, mid)
  +near = back_cm(ring)
  +far = U32.add(near, depth)
  +a = front_pt(i, j, side, t0, near, seed)
  +b = front_pt(i, j, side, t1, near, seed)
  +bc = front_pt(i, j, side, t1, far, seed)
  +ad = front_pt(i, j, side, t0, far, seed)
  +w = length(a, b)
  +here = mid_pt(mid_pt(a, bc), mid_pt(ad, b))
  lot_of(pt_x(here), pt_z(here), w, depth, kind, lot_face(f, ring), a, b, bc, ad)

# ---------------------------------------------------------------------------
# The core of a block
#
# The rings stop where the block runs out of depth, and what is left in the
# middle is a kampung grid: lots on lanes three metres wide, cut from the
# block's own patch, so the grid follows the block instead of a chord across
# it. Every cell is one lot, and the lane between two cells is the gang the
# lots face. The grid is the same offset subdivision the rings use, one level
# further in.
# ---------------------------------------------------------------------------

# The widest kerb any of the block's four streets asks for.
def kerb_widest(+i: U32, +j: U32) -> U32:
  U32.max(U32.max(kerb_cm(i, j, 0), kerb_cm(i, j, 1)),
          U32.max(kerb_cm(i, j, 2), kerb_cm(i, j, 3)))

# A street between two nodes bows away from the chord between them, and a row
# stands on the street, not on the chord: the bow is what keeps a deep lot from
# reaching the core. A Catmull-Rom segment never bows past a sixth of the second
# difference the wave can make, so a sixth of the swing bounds every street in
# the town without sampling one.
def bulge_cm() -> U32:
  U32.div(swing_cm(), 8)

# How far the core stands from the block's edge.
def core_margin_cm(+i: U32, +j: U32, +seed: U32) -> U32:
  U32.add(kerb_widest(i, j),
          U32.add(U32.add(bulge_cm(), 50),
                  U32.mul(rings_in(i, j, seed), U32.add(row_depth_cm(), gang_cm()))))

# The core needs the middle of the block, not four streets round it. A block
# loses a side where a street stops short into a T or where the river runs, and
# that side carries no frontage, but the ground in the middle is still the
# block's own and still gets built. Only a block too narrow for its own
# frontages has no middle to speak of.
def core_ready(+i: U32, +j: U32, +seed: U32) -> Bool:
  +m = core_margin_cm(i, j, seed)
  U32.is_lt(U32.add(U32.mul(2, m), 600),
            U32.min(block_depth(i, j, seed), block_width(i, j, seed)))

# A point of the core, given in thousand-and-twenty-fourths of the core itself,
# placed on the block's patch. Nothing here is pushed along a frame, so the four
# corners are the patch's own corners and the grid cannot fold.
def core_at(+i: U32, +j: U32, +u: U32, +v: U32, +seed: U32) -> Pt:
  +m = core_margin_cm(i, j, seed)
  +w = U32.max(block_width(i, j, seed), 1)
  +d = U32.max(block_depth(i, j, seed), 1)
  +bu = U32.div(U32.add(U32.mul(m, 1024), U32.mul(u, U32.sub(w, U32.min(w, U32.mul(2, m))))), w)
  +bv = U32.div(U32.add(U32.mul(m, 1024), U32.mul(v, U32.sub(d, U32.min(d, U32.mul(2, m))))), d)
  quad_point(site(i, j, seed), site(U32.add(i, 1), j, seed),
             site(U32.add(i, 1), U32.add(j, 1), seed), site(i, U32.add(j, 1), seed), bu, bv)

def core_width(+i: U32, +j: U32, +seed: U32) -> U32:
  U32.sub(block_width(i, j, seed), U32.min(block_width(i, j, seed),
                                           U32.mul(2, core_margin_cm(i, j, seed))))

def core_depth(+i: U32, +j: U32, +seed: U32) -> U32:
  U32.sub(block_depth(i, j, seed), U32.min(block_depth(i, j, seed),
                                           U32.mul(2, core_margin_cm(i, j, seed))))

# Cells are 12 m wide at their nominal share, so the lane between two of them
# is 3 m and the lot between two lanes is 9 m: a kampung plot with a yard.
def core_pitch_cm() -> U32:
  1200

# Cells no wider than the pitch: round up, so a cell never grows past the yard
# it is meant to leave.
def cells_of(room_cm: U32) -> U32:
  U32.div(U32.add(room_cm, U32.sub(core_pitch_cm(), 1)), core_pitch_cm())

def core_built(+i: U32, +j: U32, +seed: U32) -> Bool:
  core_ready(i, j, seed)

def core_lots_w(+i: U32, +j: U32, +seed: U32) -> U32:
  Bool.pick(U32, core_built(i, j, seed),
            U32.min(U32.max(cells_of(core_width(i, j, seed)), 1), 8), 0)

def core_lots_d(+i: U32, +j: U32, +seed: U32) -> U32:
  Bool.pick(U32, core_built(i, j, seed),
            U32.min(U32.max(cells_of(core_depth(i, j, seed)), 1), 8), 0)

# What one column, or one row, of a core takes of its thousand: seven tenths to
# one and a half, dealt from the block's own seed. A kampung is not a grid of
# equal squares — a plot is 6 m at one end of the lane and 14 m at the other —
# and a block whose middle is one cell size repeated is the thing that reads as
# a car park from above.
def core_share(+i: U32, +j: U32, +k: U32, +seed: U32, +across: Bool) -> U32:
  +salt = Bool.pick(U32, across, 3, 97)
  +roll = U32.mod(mix(U32.add(k, salt),
                     U32.add(seed, U32.add(U32.mul(i, 31), U32.mul(j, 17)))), 100)
  U32.add(700, U32.mul(roll, 8))

# The shares of the first `k` columns, or rows, added up. Every cell of a core
# is cut from these, so the cells tile the core exactly however uneven they are.
def core_weight(fuel: Nat, +k: U32, +i: U32, +j: U32, +seed: U32, +across: Bool) -> U32:
  match fuel:
    case 0n:
      0
    case 1n+p:
      Bool.pick(U32, U32.is_eq(k, 0), 0,
                U32.add(core_share(i, j, U32.sub(k, 1), seed, across),
                        core_weight(p, U32.sub(k, 1), i, j, seed, across)))

# The edge of column, or row, `k` in thousand-and-twenty-fourths of the core.
def core_edge(+k: U32, +i: U32, +j: U32, +seed: U32, +across: Bool, +n: U32) -> U32:
  +total = U32.max(core_weight(U32.to_nat(n), n, i, j, seed, across), 1)
  U32.div(U32.mul(core_weight(U32.to_nat(k), k, i, j, seed, across), 1024), total)

# A yard block keeps its square rather than losing its middle: the cells whose
# own middle sits within a third of the core's middle are left open, and the
# grid is built round them. That is the alun-alun a kelurahan keeps — a lapangan
# with a row of shops on every side of it — and not a field with one row of
# houses along two of its edges.
def core_mid(+i: U32, +j: U32, +k: U32, +across: Bool, +seed: U32) -> Bool:
  +n = Bool.pick(U32, across, core_lots_w(i, j, seed), core_lots_d(i, j, seed))
  +mid = U32.div(U32.add(core_edge(k, i, j, seed, across, n),
                         core_edge(U32.add(k, 1), i, j, seed, across, n)), 2)
  +apart = Bool.pick(U32, U32.is_le(512, mid), U32.sub(mid, 512), U32.sub(512, mid))
  U32.is_lt(apart, 160)

# A boundary between two core cells is a gang or a shared wall, decided by the
# block's own seed: a gang a little under half the time, three metres wide, and
# a wall gap where two houses stand against each other. That is what a kampung
# looks like from above — terraces, broken by lanes that go somewhere.
def core_boundary_lane(+i: U32, +j: U32, +k: U32, +across: Bool, +seed: U32) -> Bool:
  +salt = Bool.pick(U32, across, 11, 71)
  +roll = U32.mod(mix(U32.add(k, salt),
                     U32.add(seed, U32.add(U32.mul(i, 29), U32.mul(j, 43)))), 100)
  U32.is_lt(roll, 46)

# The gap one side of a boundary takes: half a gang, or half a wall gap.
def core_lane_cm(+i: U32, +j: U32, +k: U32, +across: Bool, +seed: U32) -> U32:
  Bool.pick(U32, core_boundary_lane(i, j, k, across, seed), 150, 5)

# Some cells are not built at all: an eighth of them stand open as a kebun, a
# yard with a tree in it, which is where a kampung keeps its shade.
def core_garden(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Bool:
  +roll = U32.mod(mix(U32.add(a, U32.mul(b, 13)),
                     U32.add(seed, U32.add(U32.mul(i, 61), U32.mul(j, 19)))), 100)
  U32.is_lt(roll, 13)

def core_open(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Bool:
  Bool.or(Bool.and(block_yard(i, j, seed),
                   Bool.and(core_mid(i, j, a, True{}, seed), core_mid(i, j, b, False{}, seed))),
          Bool.and(core_built(i, j, seed), core_garden(i, j, a, b, seed)))

# A core lot faces its lane: rows alternate, so both sides of a lane have a
# front, and every lot in the middle of a block still faces something. The lane
# runs between two rows, and the houses along one row share their side walls,
# which is what makes a kampung row a terrace and not a row of detached boxes.
def core_face(+i: U32, +j: U32, +b: U32, +seed: U32) -> Vec:
  +p = site(i, j, seed)
  +q = site(i, U32.add(j, 1), seed)
  +deep = block_depth(i, j, seed)
  +ux = unit(pt_x(p), pt_x(q), deep)
  +uz = unit(pt_z(p), pt_z(q), deep)
  Bool.pick(Vec, U32.is_eq(U32.mod(b, 2), 0), Vec{ux, uz}, Vec{negate(ux), negate(uz)})

# What stands in a core cell: the kampung mix, drawn from the cell's own roll
# and narrowed to the kinds that fit the ground the cell actually got. A cell
# too narrow for a house is a petak, and the widths differ by design, so one
# block shows a shop-house, a boarding house and a yard's worth of sheds.
def fits_or(+k: LotKind, +other: LotKind, +w: U32) -> LotKind:
  Bool.pick(LotKind, kind_fits(k, w), k, other)

# One roll, one kind, out of the catalogue the renderer carries: a house, a
# boarding house, a pengisi, a shop-house, a warung, a warehouse, a minimarket
# or a workshop, each where the cell's own ground is wide enough for it and a
# petak where it is not. The roll is the cell's, so two cells side by side are
# two different buildings and no block is one recipe.
def core_kind_pick(+w: U32, +roll: U32) -> LotKind:
  Bool.pick(LotKind, U32.is_lt(roll, 20),
            fits_or(House{}, Petak{}, w),
            Bool.pick(LotKind, U32.is_lt(roll, 38),
                      fits_or(Kos{}, Petak{}, w),
                      Bool.pick(LotKind, U32.is_lt(roll, 54),
                                fits_or(Filler{}, Petak{}, w),
                                Bool.pick(LotKind, U32.is_lt(roll, 68),
                                          fits_or(Ruko{}, Warung{}, w),
                                          Bool.pick(LotKind, U32.is_lt(roll, 78),
                                                    fits_or(Warung{}, Petak{}, w),
                                                    Bool.pick(LotKind, U32.is_lt(roll, 86),
                                                              fits_or(Gudang{}, Petak{}, w),
                                                              Bool.pick(LotKind, U32.is_lt(roll, 93),
                                                                        fits_or(Minimarket{}, Petak{}, w),
                                                                        fits_or(Bengkel{}, Petak{}, w))))))))

def core_kind(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32, +w: U32) -> LotKind:
  +roll = U32.mod(mix(U32.add(a, U32.mul(b, 7)),
                     U32.add(seed, U32.add(U32.mul(i, 37), U32.mul(j, 53)))), 100)
  core_kind_pick(w, roll)

# One cell of a core: its own four edges, a wall gap in from the two sides it
# shares with the houses beside it and a lane in from the two it shares with the
# lane behind, and the kind that fits the ground it got. Nothing is shared with
# the cell beside it but the edge itself, so a core tiles whether its cells are
# equal or not.
def core_lot_at(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Lot:
  +nw = core_lots_w(i, j, seed)
  +nd = core_lots_d(i, j, seed)
  +wide = U32.max(core_width(i, j, seed), 1)
  +deep = U32.max(core_depth(i, j, seed), 1)
  +u0 = core_edge(a, i, j, seed, True{}, nw)
  +u1 = core_edge(U32.add(a, 1), i, j, seed, True{}, nw)
  +v0 = core_edge(b, i, j, seed, False{}, nd)
  +v1 = core_edge(U32.add(b, 1), i, j, seed, False{}, nd)
  +lu0 = U32.min(U32.div(U32.mul(core_lane_cm(i, j, a, True{}, seed), 512), wide),
                 U32.div(U32.sub(u1, u0), 2))
  +lu1 = U32.min(U32.div(U32.mul(core_lane_cm(i, j, U32.add(a, 1), True{}, seed), 512), wide),
                 U32.div(U32.sub(u1, u0), 2))
  +lv0 = U32.min(U32.div(U32.mul(core_lane_cm(i, j, b, False{}, seed), 512), deep),
                 U32.div(U32.sub(v1, v0), 2))
  +lv1 = U32.min(U32.div(U32.mul(core_lane_cm(i, j, U32.add(b, 1), False{}, seed), 512), deep),
                 U32.div(U32.sub(v1, v0), 2))
  +w = U32.div(U32.mul(wide, U32.sub(U32.sub(u1, u0), U32.add(lu0, lu1))), 1024)
  +d = U32.div(U32.mul(deep, U32.sub(U32.sub(v1, v0), U32.add(lv0, lv1))), 1024)
  +c0 = core_at(i, j, U32.add(u0, lu0), U32.add(v0, lv0), seed)
  +c1 = core_at(i, j, U32.sub(u1, lu1), U32.add(v0, lv0), seed)
  +c2 = core_at(i, j, U32.sub(u1, lu1), U32.sub(v1, lv1), seed)
  +c3 = core_at(i, j, U32.add(u0, lu0), U32.sub(v1, lv1), seed)
  +here = mid_pt(mid_pt(c0, c2), mid_pt(c1, c3))
  lot_of(pt_x(here), pt_z(here), w, d, core_kind(i, j, a, b, seed, w),
         core_face(i, j, a, seed), c0, c1, c2, c3)

# The edges of a core, walked by counting up: each one stands past the last, so
# the cells of a core tile its ground however uneven the shares that cut them.
def core_edges_rise(fuel: Nat, +k: U32, +i: U32, +j: U32, +across: Bool, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +n = Bool.pick(U32, across, core_lots_w(i, j, seed), core_lots_d(i, j, seed))
      +ok = Bool.or(U32.is_le(n, k),
                    U32.is_le(core_edge(k, i, j, seed, across, n),
                              core_edge(U32.add(k, 1), i, j, seed, across, n)))
      Bool.and(ok, core_edges_rise(p, U32.add(k, 1), i, j, across, seed))

# ---------------------------------------------------------------------------
# Reading the lots back, so a law can walk a block.
# ---------------------------------------------------------------------------

def lot_inside(l: Lot) -> Bool:
  match l:
    case Lot{+x, +z, fx, fz, w, d, kind, ax, az, bx, bz, cx, cz, dx, dz}:
      Bool.and(U32.is_lt(0, x), Bool.and(U32.is_lt(x, 90000),
      Bool.and(U32.is_lt(0, z), U32.is_lt(z, 90000))))

# The first and last lot of every row of a block, walked by counting sides up
# over all the rings the block has. Between them they carry the ends of every
# row, which is where a lot could leave the town.
def rows_walk(fuel: Nat, +ring: U32, +side: U32, +i: U32, +j: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +lots = lots_on(i, j, side, ring, seed)
      +ok = Bool.or(U32.is_eq(lots, 0),
                    Bool.and(lot_inside(lot_at(i, j, side, ring, 0, seed)),
                             lot_inside(lot_at(i, j, side, ring, U32.sub(lots, 1), seed))))
      Bool.and(ok, rows_walk(p, U32.add(ring, 1), side, i, j, seed))

def sides_inside(fuel: Nat, +side: U32, +i: U32, +j: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      Bool.and(rows_walk(U32.to_nat(rings_in(i, j, seed)), 0, side, i, j, seed),
               sides_inside(p, U32.add(side, 1), i, j, seed))

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

# ---------------------------------------------------------------------------
# The corners, read back
#
# The mitre leans on one fact about the field: no block corner is sharper than a
# sine of seventeen twentieths, which is the fifty-eight degrees a mitre of
# cot(theta/2) spreads to under two. That is a property of this lattice, so it is
# a law and not a promise.
#
# The sine arrives as the cross product of the two chords that meet at the
# corner, over the product of their lengths. Wrapped differences are two's
# complement, so a product of them is the signed product and the sign is the top
# bit; the comparison is taken a twentieth at a time so no product leaves a
# thirty-two-bit number.
# ---------------------------------------------------------------------------

def corner_square(+o: Pt, +a: Pt, +b: Pt) -> Bool:
  match o:
    case Pt{ox, oz}:
      match a:
        case Pt{ax, az}:
          match b:
            case Pt{bx, bz}:
              +ux = U32.sub(ax, ox)
              +uz = U32.sub(az, oz)
              +vx = U32.sub(bx, ox)
              +vz = U32.sub(bz, oz)
              +cross = mag_of(U32.sub(U32.mul(ux, vz), U32.mul(uz, vx)))
              +share = U32.mul(U32.div(U32.mul(length(o, a), length(o, b)), 20), 17)
              U32.is_le(share, cross)

def every_corner(fuel: Nat, +c: U32, +i: U32, +j: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +back = U32.mod(U32.add(c, 3), 4)
      +ahead = U32.mod(U32.add(c, 1), 4)
      +ok = corner_square(site(corner_i(i, c), corner_j(j, c), seed),
                          site(corner_i(i, back), corner_j(j, back), seed),
                          site(corner_i(i, ahead), corner_j(j, ahead), seed))
      Bool.and(ok, every_corner(p, ahead, i, j, seed))

# Every corner of every block in the field, walked by counting the lattice up.
def every_block_corner(fuel: Nat, +n: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +i = U32.mod(n, cols())
      +j = U32.div(n, cols())
      +ok = Bool.or(Bool.not(block_exists(i, j)), every_corner(4n, 0, i, j, seed))
      Bool.and(ok, every_block_corner(p, U32.add(n, 1), seed))

# ===========================================================================
# The pavement: one prop in front of every frontage lot
#
# A tree, a hedge, a pole or a pot stands on the pavement in front of each lot
# of a block's frontage ring, on that lot's own centre line. Two props are
# therefore one lot apart, and no lot is cut narrower than twice the widest
# crown, so no two crowns can meet — which is the Permen PU 05/PRT/M/2012 rule
# that street trees are set out at their crown diameter, kept by construction
# instead of by test. Nothing is sampled and nothing is rejected.
#
# The prop stands half a metre off the kerb, the planting line the same
# regulation sets, and within twenty metres of a junction only low planting
# stands, so the approach keeps the sight distance the guideline asks of it.
# Poles stand on one pavement of each street, one every seventh lot: seven lots
# of six metres is PLN's span for a low-voltage line.
# ===========================================================================

type PropKind is Data:
  Mangga{}
  Palm{}
  Kamboja{}
  Semak{}
  Pole{}
  Pot{}

# The ground a prop takes: half a crown for a tree, half its length for a hedge
# and a small footprint for furniture. The view draws a tree to this radius.
def crown_cm(k: PropKind) -> U32:
  match k:
    case Mangga{}:
      220
    case Palm{}:
      200
    case Kamboja{}:
      130
    case Semak{}:
      150
    case Pole{}:
      20
    case Pot{}:
      70

# The widest crown any prop reaches. A lot has to hold two of them.
def widest_crown_cm() -> U32:
  220

# How far a prop stands from its street's centre line: half a metre off the
# kerb, which is inside the pavement and in front of every building.
def prop_off_cm(+i: U32, +j: U32, +side: U32) -> U32:
  U32.add(half_cm(street_of(side_i(i, side), side_j(j, side), side_dir(side))), 50)

# Within twenty metres of a junction only low planting stands. The lot is
# measured from the node, not from the end of the frontage, because the mouth
# already stands a kerb return and half the crossing street away from it.
def prop_low(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Bool:
  +w = lot_width(i, j, side, 0, seed)
  +at = U32.add(U32.mul(t, w), U32.div(w, 2))
  +near = mouth_cm(side_i(i, side), side_j(j, side), side_dir(side), seed)
  +far = mouth_cm(far_i(i, side), far_j(j, side), opposite(side_dir(side)), seed)
  Bool.or(U32.is_lt(U32.add(near, at), 2200),
          U32.is_lt(U32.add(far, U32.sub(frontage_cm(i, j, side, 0, seed), at)), 2200))

# A pole every seventh lot, on one pavement of each street.
def prop_pole(+side: U32, +t: U32) -> Bool:
  Bool.and(U32.is_lt(side, 2), U32.is_eq(U32.mod(t, 7), 3))

def prop_pick(low: Bool, pole: Bool, +roll: U32) -> PropKind:
  Bool.pick(PropKind, pole, Pole{},
            Bool.pick(PropKind, low, Semak{},
                      Bool.pick(PropKind, U32.is_lt(roll, 52), Mangga{},
                                Bool.pick(PropKind, U32.is_lt(roll, 78), Palm{},
                                          Bool.pick(PropKind, U32.is_lt(roll, 90), Kamboja{},
                                                    Pot{})))))

def prop_kind(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> PropKind:
  +roll = U32.mod(mix(U32.add(t, U32.mul(side, 17)), U32.add(seed, U32.mul(i, 13))), 100)
  prop_pick(prop_low(i, j, side, t, seed), prop_pole(side, t), roll)

type Prop is Data:
  Prop{x: U32, z: U32, r: U32, kind: PropKind}

def push_out(p: Pt, +f: Frame, +side: U32, +reach: U32) -> Pt:
  match p:
    case Pt{px, pz}:
      Pt{push_along(px, negate(inward_x(f, side)), reach),
         push_along(pz, negate(inward_z(f, side)), reach)}

# The prop in front of lot t of a frontage: the lot's centre line, moved back
# out to the planting line.
def prop_at(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Prop:
  +mid = U32.div(U32.add(lot_edge_t(i, j, side, 0, t, seed),
                        lot_edge_t(i, j, side, 0, U32.add(t, 1), seed)), 2)
  +kind = prop_kind(i, j, side, t, seed)
  +c = curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed)
  +here = advance(at(c, mid), frame_on(c, side, mid), prop_off_cm(i, j, side))
  Prop{pt_x(here), pt_z(here), crown_cm(kind), kind}

# A prop stands between the kerb and the far side of the pavement: never in the
# carriageway, never where the buildings begin.
def prop_on_pavement(+i: U32, +j: U32, +side: U32) -> Bool:
  +half = half_cm(street_of(side_i(i, side), side_j(j, side), side_dir(side)))
  Bool.and(U32.is_lt(half, prop_off_cm(i, j, side)),
           U32.is_lt(prop_off_cm(i, j, side), U32.add(half, pavement_cm())))

# Where the tree of an open cell stands: the middle of the cell, and a kind
# drawn from the cell's own roll, so the shade in a block is not one species.
def core_tree_kind(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> PropKind:
  +roll = U32.mod(mix(U32.add(a, U32.mul(b, 29)),
                     U32.add(seed, U32.add(U32.mul(i, 7), U32.mul(j, 23)))), 100)
  Bool.pick(PropKind, U32.is_lt(roll, 40), Mangga{},
            Bool.pick(PropKind, U32.is_lt(roll, 70), Palm{}, Kamboja{}))

def core_tree(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Prop:
  +nw = core_lots_w(i, j, seed)
  +nd = core_lots_d(i, j, seed)
  +u = U32.div(U32.add(core_edge(a, i, j, seed, True{}, nw),
                       core_edge(U32.add(a, 1), i, j, seed, True{}, nw)), 2)
  +v = U32.div(U32.add(core_edge(b, i, j, seed, False{}, nd),
                       core_edge(U32.add(b, 1), i, j, seed, False{}, nd)), 2)
  +kind = core_tree_kind(i, j, a, b, seed)
  +p = core_at(i, j, u, v, seed)
  Prop{pt_x(p), pt_z(p), crown_cm(kind), kind}

# Every prop of a frontage, walked by counting lots up: two crowns are narrower
# than the lot between them, and a tree never stands near a junction.
def props_apart(fuel: Nat, +t: U32, +i: U32, +j: U32, +side: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +next = U32.add(t, 1)
      +live = U32.is_lt(next, lots_on(i, j, side, 0, seed))
      +pair = U32.add(crown_cm(prop_kind(i, j, side, t, seed)),
                      crown_cm(prop_kind(i, j, side, next, seed)))
      +ok = Bool.or(Bool.not(live), U32.is_le(pair, lot_width(i, j, side, 0, seed)))
      Bool.and(ok, props_apart(p, next, i, j, side, seed))

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
