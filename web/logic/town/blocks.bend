# lajur — the town: The blocks between the streets, their frames and their lots.
# Part of town.bend, which names the town's functions for the page.
import Base
import ./lattice.bend as Lat
import ./streets.bend as Str
import ./junction.bend as Jun

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
      +next = U32.shrn(U32.add(x, U32.div(n, U32.max(x, 1))), 1n)
      root(p, n, Bool.pick(U32, U32.is_le(x, next), x, next))

# Newton from the first power of two at or above the root, so the estimate is
# within a factor of two and six steps reach the root of any thirty-two-bit
# number. Starting from the number itself took twenty, and a root is the most
# expensive thing the checker evaluates: a division a step.
def sqrt_start(+n: U32) -> U32:
  U32.shln(1, U32.to_nat(U32.shrn(U32.add(U32.from_nat(U32.log2(n)), 2), 1n)))

def sqrt(+n: U32) -> U32:
  root(6n, n, U32.min(sqrt_start(n), 65535))

def length(a: Lat.Pt, b: Lat.Pt) -> U32:
  match a:
    case Lat.Pt{ax, az}:
      match b:
        case Lat.Pt{bx, bz}:
          +dx = U32.sub(bx, ax)
          +dz = U32.sub(bz, az)
          sqrt(U32.add(U32.mul(dx, dx), U32.mul(dz, dz)))

def mix_pt(p: Lat.Pt, q: Lat.Pt, +t: U32) -> Lat.Pt:
  match p:
    case Lat.Pt{px, pz}:
      match q:
        case Lat.Pt{qx, qz}:
          Lat.Pt{Str.lerp(px, qx, t), Str.lerp(pz, qz, t)}

# The block as a bilinear patch: a point is found by travelling `u` along the
# south edge and `v` from there to the north edge.
def quad_point(a: Lat.Pt, b: Lat.Pt, c: Lat.Pt, d: Lat.Pt, +u: U32, +v: U32) -> Lat.Pt:
  mix_pt(mix_pt(a, b, u), mix_pt(d, c, u), v)

def span_of(s: Lat.Signed) -> U32:
  match s:
    case Lat.Signed{size, down}:
      size

# A direction as a step of 1024, sign kept.
def unit(a: U32, b: U32, wide: U32) -> Lat.Signed:
  +d = Str.gap_cm(a, b)
  Lat.Signed{U32.div(U32.mul(span_of(d), 1024), U32.max(wide, 1)), Lat.below(d)}

def push_along(base: U32, u: Lat.Signed, dist: U32) -> U32:
  match u:
    case Lat.Signed{size, down}:
      Lat.place(base, U32.shrn(U32.mul(size, dist), 10n), down)

type Frame is Data:
  Frame{origin: Lat.Pt, ux: Lat.Signed, uz: Lat.Signed, nx: Lat.Signed, nz: Lat.Signed}

# The block's own axes: along its row j street, and into the block.
def chord(ax: U32, az: U32, bx: U32, bz: U32) -> U32:
  +dx = U32.sub(bx, ax)
  +dz = U32.sub(bz, az)
  sqrt(U32.add(U32.mul(dx, dx), U32.mul(dz, dz)))

def inwards_x(ux: Lat.Signed, uz: Lat.Signed) -> Lat.Signed:
  match uz:
    case Lat.Signed{size, down}:
      Lat.Signed{size, Bool.not(down)}

def inwards_z(ux: Lat.Signed, uz: Lat.Signed) -> Lat.Signed:
  match ux:
    case Lat.Signed{size, down}:
      Lat.Signed{size, down}

def frame_from(a: Lat.Pt, b: Lat.Pt) -> Frame:
  match a:
    case Lat.Pt{+ax, +az}:
      match b:
        case Lat.Pt{+bx, +bz}:
          +wide = chord(ax, az, bx, bz)
          +ux = unit(ax, bx, wide)
          +uz = unit(az, bz, wide)
          Frame{Lat.Pt{ax, az}, ux, uz, inwards_x(ux, uz), inwards_z(ux, uz)}

def frame_of(+i: U32, +j: U32, +seed: U32) -> Frame:
  frame_from(Lat.site(i, j, seed), Lat.site(U32.add(i, 1), j, seed))

def negate(s: Lat.Signed) -> Lat.Signed:
  match s:
    case Lat.Signed{size, down}:
      Lat.Signed{size, Bool.not(down)}

# A block's south street and north street, which are rows j and j+1.
def south_half(+i: U32, +j: U32) -> U32:
  Jun.half_cm(Jun.street_of(i, j, Str.East{}))

def north_half(+i: U32, +j: U32) -> U32:
  Jun.half_cm(Jun.street_of(i, U32.add(j, 1), Str.East{}))

def pavement_cm() -> U32:
  150

def row_depth_cm() -> U32:
  1300

def gang_cm() -> U32:
  200

def block_depth(+i: U32, +j: U32, +seed: U32) -> U32:
  length(Lat.site(i, j, seed), Lat.site(i, U32.add(j, 1), seed))

def block_width(+i: U32, +j: U32, +seed: U32) -> U32:
  length(Lat.site(i, j, seed), Lat.site(U32.add(i, 1), j, seed))

# A block exists where both of the streets that bound it do. The river leaves
# a column of cells with no east street, and those are water, not blocks.
def block_exists(+i: U32, +j: U32) -> Bool:
  Bool.and(Str.has(i, j, Str.East{}), Str.has(i, j, Str.South{}))

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

def side_dir(side: U32) -> Str.Dir:
  Bool.pick(Str.Dir, U32.is_eq(U32.and(side, 1), 0), Str.East{}, Str.South{})

# The node at the far end of that frontage.
def far_i(+i: U32, +side: U32) -> U32:
  Bool.pick(U32, U32.is_eq(side, 3), i, U32.add(i, 1))

def far_j(+j: U32, +side: U32) -> U32:
  Bool.pick(U32, U32.is_eq(side, 0), j, U32.add(j, 1))

# A frontage only exists where its street does. The river leaves a column with
# no street, and the edge of the town leaves the blocks beside it without one,
# so a side that has no street carries no lot.
def side_open(+i: U32, +j: U32, +side: U32) -> Bool:
  Str.has(side_i(i, side), side_j(j, side), side_dir(side))

def side_len(+i: U32, +j: U32, +side: U32, +seed: U32) -> U32:
  length(Lat.site(side_i(i, side), side_j(j, side), seed),
         Lat.site(far_i(i, side), far_j(j, side), seed))

def inward_x(f: Frame, +side: U32) -> Lat.Signed:
  match f:
    case Frame{origin, +ux, +uz, +nx, +nz}:
      Bool.pick(Lat.Signed, U32.is_lt(side, 2),
                Bool.pick(Lat.Signed, U32.is_eq(side, 0), nx, negate(ux)),
                Bool.pick(Lat.Signed, U32.is_eq(side, 2), negate(nx), ux))

def inward_z(f: Frame, +side: U32) -> Lat.Signed:
  match f:
    case Frame{origin, +ux, +uz, +nx, +nz}:
      Bool.pick(Lat.Signed, U32.is_lt(side, 2),
                Bool.pick(Lat.Signed, U32.is_eq(side, 0), nz, negate(uz)),
                Bool.pick(Lat.Signed, U32.is_eq(side, 2), negate(nz), uz))

def mid_pt(a: Lat.Pt, b: Lat.Pt) -> Lat.Pt:
  match a:
    case Lat.Pt{ax, az}:
      match b:
        case Lat.Pt{bx, bz}:
          Lat.Pt{U32.shrn(U32.add(ax, bx), 1n), U32.shrn(U32.add(az, bz), 1n)}

# A point pushed `reach` centimetres into the block from the side it is on.
def push_in(p: Lat.Pt, +f: Frame, +side: U32, +reach: U32) -> Lat.Pt:
  match p:
    case Lat.Pt{px, pz}:
      Lat.Pt{push_along(px, inward_x(f, side), reach), push_along(pz, inward_z(f, side), reach)}

# How far a frontage line stands from its street's centre line.
def kerb_cm(+i: U32, +j: U32, +side: U32) -> U32:
  U32.add(Jun.half_cm(Jun.street_of(side_i(i, side), side_j(j, side), side_dir(side))), pavement_cm())

# A step of 1024 along the path from a to b.
def unit_of(a: Lat.Pt, b: Lat.Pt) -> Str.Vec:
  match a:
    case Lat.Pt{+ax, +az}:
      match b:
        case Lat.Pt{+bx, +bz}:
          +wide = length(a, b)
          Str.Vec{unit(ax, bx, wide), unit(az, bz, wide)}

def negate_vec(v: Str.Vec) -> Str.Vec:
  match v:
    case Str.Vec{ux, uz}:
      Str.Vec{negate(ux), negate(uz)}

# The normal that points into the block, from the way the street runs. Sides 0
# and 1 run with the block's winding, so the left of travel is the block; sides
# 2 and 3 run against it, so the left of travel is the street.
def inward_of(v: Str.Vec, +side: U32) -> Str.Vec:
  match v:
    case Str.Vec{+ux, +uz}:
      +left: Str.Vec = Str.Vec{Lat.Signed{span_of(uz), Bool.not(Lat.below(uz))}, Lat.Signed{span_of(ux), Lat.below(ux)}}
      Bool.pick(Str.Vec, U32.is_lt(side, 2), left, negate_vec(left))

# The street's frame at a fraction of its length: where it is, which way it
# runs, and which way the block lies. Every lot is drawn in one of these, so a
# row follows the street instead of the block's chord.
def frame_join(origin: Lat.Pt, v: Str.Vec, n: Str.Vec) -> Frame:
  match v:
    case Str.Vec{ux, uz}:
      match n:
        case Str.Vec{nx, nz}:
          Frame{origin, ux, uz, nx, nz}

def frame_on(+c: Str.Curve, +side: U32, +t: U32) -> Frame:
  +lo = Str.at(c, U32.sub(t, U32.min(t, 12)))
  +hi = Str.at(c, U32.min(U32.add(t, 12), 1024))
  +v = unit_of(lo, hi)
  frame_join(Str.at(c, t), v, inward_of(v, side))

def frame_at(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Frame:
  frame_on(Str.curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed), side, t)

# A point `reach` centimetres from `p`, along the frame's normal.
def advance(p: Lat.Pt, +f: Frame, +reach: U32) -> Lat.Pt:
  match p:
    case Lat.Pt{px, pz}:
      match f:
        case Frame{origin, ux, uz, nx, nz}:
          Lat.Pt{push_along(px, nx, reach), push_along(pz, nz, reach)}

# A point on a frontage line: a fraction of the street, in thousand-and-
# twenty-fourths, pushed into the block past the kerb and `back` centimetres
# further. The push follows the street's own normal, so the line is a frontage
# and not a chord.
def front_pt(+i: U32, +j: U32, +side: U32, +t: U32, +back: U32, +seed: U32) -> Lat.Pt:
  +c = Str.curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed)
  advance(Str.at(c, t), frame_on(c, side, t), U32.add(kerb_cm(i, j, side), back))

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
  U32.mod(Lat.mix(U32.add(i, 11), U32.add(j, 7)), 100)

def block_yard(+i: U32, +j: U32, +seed: U32) -> Bool:
  U32.is_lt(block_roll(i, j, seed), 12)

def block_kit(+i: U32, +j: U32, +seed: U32) -> Bool:
  U32.is_lt(block_roll(i, j, seed), 88)

# How many rings of lots fit between two opposite frontages before they meet.
def rings_in(+i: U32, +j: U32, +seed: U32) -> U32:
  +room = U32.sub(U32.min(block_depth(i, j, seed), block_width(i, j, seed)),
                  U32.mul(2, U32.add(Jun.half_cm(Jun.Ring{}), pavement_cm())))
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
  +back = U32.and(U32.add(c, 3), 3)
  +ahead = U32.and(U32.add(c, 1), 3)
  +o = Lat.site(corner_i(i, c), corner_j(j, c), seed)
  +a = Lat.site(corner_i(i, back), corner_j(j, back), seed)
  +b = Lat.site(corner_i(i, ahead), corner_j(j, ahead), seed)
  +ux = U32.sub(Lat.pt_x(a), Lat.pt_x(o))
  +uz = U32.sub(Lat.pt_z(a), Lat.pt_z(o))
  +vx = U32.sub(Lat.pt_x(b), Lat.pt_x(o))
  +vz = U32.sub(Lat.pt_z(b), Lat.pt_z(o))
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
  U32.max(Jun.mouth_cm(side_i(i, side), side_j(j, side), side_dir(side), seed),
          mitre_cut_cm(i, j, side, side, ring, seed))

def far_cut_cm(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  U32.max(Jun.mouth_cm(far_i(i, side), far_j(j, side), Jun.opposite(side_dir(side)), seed),
          mitre_cut_cm(i, j, side, U32.and(U32.add(side, 1), 3), ring, seed))

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
def cut_step(fuel: Nat, +c: Str.Curve, +o: Lat.Pt, +far: Bool, +cm: U32, +lo: U32, +hi: U32) -> U32:
  match fuel:
    case 0n:
      lo
    case 1n+p:
      +mid = U32.shrn(U32.add(lo, hi), 1n)
      +t = Bool.pick(U32, far, U32.sub(1024, mid), mid)
      +q = Str.at(c, t)
      +dx = U32.sub(Lat.pt_x(q), Lat.pt_x(o))
      +dz = U32.sub(Lat.pt_z(q), Lat.pt_z(o))
      +short = U32.is_le(U32.mul(cm, cm), U32.add(U32.mul(dx, dx), U32.mul(dz, dz)))
      cut_step(p, c, o, far, cm, Bool.pick(U32, short, lo, mid), Bool.pick(U32, short, mid, hi))

def cut_from(+i: U32, +j: U32, +side: U32, +far: Bool, +cm: U32, +seed: U32) -> U32:
  +c = Str.curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed)
  +o = Bool.pick(Lat.Pt, far,
                 Lat.site(far_i(i, side), far_j(j, side), seed),
                 Lat.site(side_i(i, side), side_j(j, side), seed))
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
  U32.shrn(U32.mul(span_t(i, j, side, ring, seed), side_len(i, j, side, seed)), 10n)

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
      U32.min(U32.div(frontage_cm(i, j, side, ring, seed), U32.add(pitch_of(ring), lot_gap_cm())), 24)
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
          U32.div(U32.mul(t, span_t(i, j, side, ring, seed)), U32.max(lots_on(i, j, side, ring, seed), 1)))

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
  +roll = U32.mod(Lat.mix(U32.add(t, U32.mul(ring, 31)), U32.add(seed, U32.mul(side, 7))), 100)
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
  Lot{x: U32, z: U32, fx: Lat.Signed, fz: Lat.Signed, w: U32, d: U32, kind: LotKind,
      ax: U32, az: U32, bx: U32, bz: U32, cx: U32, cz: U32, dx: U32, dz: U32}

# An even ring faces the street it stands on; an odd ring faces the gang behind
# the ring in front of it.
def outward(ring: U32) -> Bool:
  U32.is_eq(U32.and(ring, 1), 0)

def lot_face(f: Frame, +ring: U32) -> Str.Vec:
  match f:
    case Frame{origin, ux, uz, nx, nz}:
      +in: Str.Vec = Str.Vec{nx, nz}
      Bool.pick(Str.Vec, outward(ring), negate_vec(in), in)

def lot_of(+x: U32, +z: U32, +w: U32, +d: U32, +kind: LotKind, face: Str.Vec, +a: Lat.Pt, +b: Lat.Pt, +c: Lat.Pt, +e: Lat.Pt) -> Lot:
  match face:
    case Str.Vec{fx, fz}:
      Lot{x, z, fx, fz, w, d, kind,
          Lat.pt_x(a), Lat.pt_z(a), Lat.pt_x(b), Lat.pt_z(b), Lat.pt_x(c), Lat.pt_z(c), Lat.pt_x(e), Lat.pt_z(e)}

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
  +mid = U32.shrn(U32.add(t0, t1), 1n)
  +c = Str.curve_of(side_i(i, side), side_j(j, side), side_dir(side), seed)
  +f = frame_on(c, side, mid)
  +near = back_cm(ring)
  +far = U32.add(near, depth)
  +a = front_pt(i, j, side, t0, near, seed)
  +b = front_pt(i, j, side, t1, near, seed)
  +bc = front_pt(i, j, side, t1, far, seed)
  +ad = front_pt(i, j, side, t0, far, seed)
  +w = length(a, b)
  +here = mid_pt(mid_pt(a, bc), mid_pt(ad, b))
  lot_of(Lat.pt_x(here), Lat.pt_z(here), w, depth, kind, lot_face(f, ring), a, b, bc, ad)

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
  U32.shrn(Str.swing_cm(), 3n)

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
def core_at(+i: U32, +j: U32, +u: U32, +v: U32, +seed: U32) -> Lat.Pt:
  +m = core_margin_cm(i, j, seed)
  +w = U32.max(block_width(i, j, seed), 1)
  +d = U32.max(block_depth(i, j, seed), 1)
  +bu = U32.div(U32.add(U32.mul(m, 1024), U32.mul(u, U32.sub(w, U32.min(w, U32.mul(2, m))))), w)
  +bv = U32.div(U32.add(U32.mul(m, 1024), U32.mul(v, U32.sub(d, U32.min(d, U32.mul(2, m))))), d)
  quad_point(Lat.site(i, j, seed), Lat.site(U32.add(i, 1), j, seed),
             Lat.site(U32.add(i, 1), U32.add(j, 1), seed), Lat.site(i, U32.add(j, 1), seed), bu, bv)

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
  +roll = U32.mod(Lat.mix(U32.add(k, salt),
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
  +mid = U32.shrn(U32.add(core_edge(k, i, j, seed, across, n),
                         core_edge(U32.add(k, 1), i, j, seed, across, n)), 1n)
  +apart = Bool.pick(U32, U32.is_le(512, mid), U32.sub(mid, 512), U32.sub(512, mid))
  U32.is_lt(apart, 160)

# A boundary between two core cells is a gang or a shared wall, decided by the
# block's own seed: a gang a little under half the time, three metres wide, and
# a wall gap where two houses stand against each other. That is what a kampung
# looks like from above — terraces, broken by lanes that go somewhere.
def core_boundary_lane(+i: U32, +j: U32, +k: U32, +across: Bool, +seed: U32) -> Bool:
  +salt = Bool.pick(U32, across, 11, 71)
  +roll = U32.mod(Lat.mix(U32.add(k, salt),
                     U32.add(seed, U32.add(U32.mul(i, 29), U32.mul(j, 43)))), 100)
  U32.is_lt(roll, 46)

# The gap one side of a boundary takes: half a gang, or half a wall gap.
def core_lane_cm(+i: U32, +j: U32, +k: U32, +across: Bool, +seed: U32) -> U32:
  Bool.pick(U32, core_boundary_lane(i, j, k, across, seed), 150, 5)

# Some cells are not built at all: an eighth of them stand open as a kebun, a
# yard with a tree in it, which is where a kampung keeps its shade.
def core_garden(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Bool:
  +roll = U32.mod(Lat.mix(U32.add(a, U32.mul(b, 13)),
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
def core_face(+i: U32, +j: U32, +b: U32, +seed: U32) -> Str.Vec:
  +p = Lat.site(i, j, seed)
  +q = Lat.site(i, U32.add(j, 1), seed)
  +deep = block_depth(i, j, seed)
  +ux = unit(Lat.pt_x(p), Lat.pt_x(q), deep)
  +uz = unit(Lat.pt_z(p), Lat.pt_z(q), deep)
  Bool.pick(Str.Vec, U32.is_eq(U32.and(b, 1), 0), Str.Vec{ux, uz}, Str.Vec{negate(ux), negate(uz)})

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
  +roll = U32.mod(Lat.mix(U32.add(a, U32.mul(b, 7)),
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
                 U32.shrn(U32.sub(u1, u0), 1n))
  +lu1 = U32.min(U32.div(U32.mul(core_lane_cm(i, j, U32.add(a, 1), True{}, seed), 512), wide),
                 U32.shrn(U32.sub(u1, u0), 1n))
  +lv0 = U32.min(U32.div(U32.mul(core_lane_cm(i, j, b, False{}, seed), 512), deep),
                 U32.shrn(U32.sub(v1, v0), 1n))
  +lv1 = U32.min(U32.div(U32.mul(core_lane_cm(i, j, U32.add(b, 1), False{}, seed), 512), deep),
                 U32.shrn(U32.sub(v1, v0), 1n))
  +w = U32.shrn(U32.mul(wide, U32.sub(U32.sub(u1, u0), U32.add(lu0, lu1))), 10n)
  +d = U32.shrn(U32.mul(deep, U32.sub(U32.sub(v1, v0), U32.add(lv0, lv1))), 10n)
  +c0 = core_at(i, j, U32.add(u0, lu0), U32.add(v0, lv0), seed)
  +c1 = core_at(i, j, U32.sub(u1, lu1), U32.add(v0, lv0), seed)
  +c2 = core_at(i, j, U32.sub(u1, lu1), U32.sub(v1, lv1), seed)
  +c3 = core_at(i, j, U32.add(u0, lu0), U32.sub(v1, lv1), seed)
  +here = mid_pt(mid_pt(c0, c2), mid_pt(c1, c3))
  lot_of(Lat.pt_x(here), Lat.pt_z(here), w, d, core_kind(i, j, a, b, seed, w),
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

def corner_square(+o: Lat.Pt, +a: Lat.Pt, +b: Lat.Pt) -> Bool:
  match o:
    case Lat.Pt{ox, oz}:
      match a:
        case Lat.Pt{ax, az}:
          match b:
            case Lat.Pt{bx, bz}:
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
      +back = U32.and(U32.add(c, 3), 3)
      +ahead = U32.and(U32.add(c, 1), 3)
      +ok = corner_square(Lat.site(corner_i(i, c), corner_j(j, c), seed),
                          Lat.site(corner_i(i, back), corner_j(j, back), seed),
                          Lat.site(corner_i(i, ahead), corner_j(j, ahead), seed))
      Bool.and(ok, every_corner(p, ahead, i, j, seed))

# Every corner of every block in the field, walked by counting the lattice up.
def every_block_corner(fuel: Nat, +n: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +i = U32.mod(n, Lat.cols())
      +j = U32.div(n, Lat.cols())
      +ok = Bool.or(Bool.not(block_exists(i, j)), every_corner(4n, 0, i, j, seed))
      Bool.and(ok, every_block_corner(p, U32.add(n, 1), seed))
