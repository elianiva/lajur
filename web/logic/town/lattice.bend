# lajur — the town: The lattice, the signed numbers and the field that bends it.
# Part of town.bend, which names the town's functions for the page.
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
  U32.is_eq(U32.and(i, 1), 0)

def major_row(j: U32) -> Bool:
  U32.is_eq(U32.and(j, 1), 0)

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
