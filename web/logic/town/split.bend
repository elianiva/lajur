# lajur — the town: The split: streets inside a block, and what the cuts leave standing.
# Part of town.bend, which names the town's functions for the page.
import Base
import ./lattice.bend as Lat
import ./streets.bend as Str
import ./junction.bend as Jun
import ./blocks.bend as Blk
import ./pavement.bend as Pav

# ===========================================================================
# The split: streets inside a block
#
# The lattice above is the coarse tier, and left alone it is a grid: every
# junction is a four-way and no street ever ends. Barthelemy and Boeing's
# hundred-city sample puts the median street network at 18% four-way junctions
# and 14% dead ends, and Indonesia is the most dispersed of the large countries
# (Barrington-Leigh and Millard-Ball). So each block is cut again, the way
# Vanegas et al. subdivide a block into parcels, but with streets.
#
# A block has its own frame: `u` runs from its west street to its east street
# and `v` from its south street to its north street, each in thousand-and-
# twenty-fourths. The frame is a Coons patch of the block's four street curves,
# so an edge of the frame is the street itself and a line of constant `u` or `v`
# bends the way the streets around it bend. The cuts are made in the frame: a
# node of the cut tree is a rectangle there, and a cut is a line of constant
# `u` or `v` that halves it. A node is a path: 1 is the block, and the children
# of p are 2p and 2p+1. A cut lands on the sides of its rectangle, so it makes a
# T at each end and never a four-way. Three kinds of cut, and one that does not
# cut:
#
#   Through  a lokal street, side to side
#   Gang     a gang, side to side, so it links
#   Stub     a gang that stops inside the block, a dead end; its block is not
#            cut again, so the dead end serves the block it stands in
#   Whole    the block is small enough, or dense enough, to stay as it is
#
# The size of a rectangle is its share of the block's own width and depth in
# centimetres, so a cut is decided by index arithmetic and the frame is only
# evaluated where a point is drawn. Whether a rectangle is cut again comes from
# a smooth density field in the plane: where it is high the blocks are small
# and the grain fine, where it is low they stay large. The column the river
# runs through is never cut: water is not a block.
# ===========================================================================

type Rect is Data:
  Rect{u0: U32, u1: U32, v0: U32, v1: U32}

type SplitKind is Data:
  Whole{}
  Through{}
  Gang{}
  Stub{}

# The deepest a block is cut: three cuts down, so at most eight rectangles.
def split_depth() -> U32:
  3

def split_roll(+i: U32, +j: U32, +p: U32, +seed: U32, +k: U32) -> U32:
  U32.mod(U32.shrn(Lat.mix(U32.add(U32.mul(U32.add(U32.mul(i, 8), j), 64), p),
                       U32.add(seed, U32.mul(k, 7919))), 12n), 1000)

# ---------------------------------------------------------------------------
# The density field: value noise on a 200 m grid, eased between its corners.
# ---------------------------------------------------------------------------

def field_cell_cm() -> U32:
  20000

def field_corner(+gx: U32, +gz: U32, +seed: U32) -> U32:
  U32.mod(Lat.mix(U32.add(U32.mul(gx, 97), gz), U32.add(seed, 31)), 1000)

def field_blend(+a: U32, +b: U32, +f: U32) -> U32:
  U32.div(U32.add(U32.mul(a, U32.sub(1000, f)), U32.mul(b, f)), 1000)

def field_at(+x: U32, +z: U32, +seed: U32) -> U32:
  +gx = U32.div(x, field_cell_cm())
  +gz = U32.div(z, field_cell_cm())
  +fx = Lat.ease(U32.div(U32.mod(x, field_cell_cm()), 20))
  +fz = Lat.ease(U32.div(U32.mod(z, field_cell_cm()), 20))
  +top = field_blend(field_corner(gx, gz, seed), field_corner(U32.add(gx, 1), gz, seed), fx)
  +bot = field_blend(field_corner(gx, U32.add(gz, 1), seed),
                     field_corner(U32.add(gx, 1), U32.add(gz, 1), seed), fx)
  field_blend(top, bot, fz)

# ---------------------------------------------------------------------------
# The frame
# ---------------------------------------------------------------------------

# A point of the block at (u, v): the two ruled surfaces between opposite
# streets, less the bilinear patch of the four corners, which both count. At
# each edge this is the street's own curve. The sum is taken before the
# difference, so nothing wraps below zero.
def patch(+i: U32, +j: U32, +u: U32, +v: U32, +seed: U32) -> Lat.Pt:
  +along = Blk.mix_pt(Str.at(Str.curve_of(i, j, Str.East{}, seed), u), Str.at(Str.curve_of(i, U32.add(j, 1), Str.East{}, seed), u), v)
  +across = Blk.mix_pt(Str.at(Str.curve_of(i, j, Str.South{}, seed), v), Str.at(Str.curve_of(U32.add(i, 1), j, Str.South{}, seed), v), u)
  +corners = Blk.quad_point(Lat.site(i, j, seed), Lat.site(U32.add(i, 1), j, seed),
                        Lat.site(U32.add(i, 1), U32.add(j, 1), seed), Lat.site(i, U32.add(j, 1), seed), u, v)
  Lat.Pt{U32.sub(U32.add(Lat.pt_x(along), Lat.pt_x(across)), Lat.pt_x(corners)),
     U32.sub(U32.add(Lat.pt_z(along), Lat.pt_z(across)), Lat.pt_z(corners))}

# The block's width along `u` and depth along `v`, in centimetres: the mean of
# its two opposite streets, each measured as the chord between its junctions.
type Size is Data:
  Size{w: U32, h: U32}

def block_size(+i: U32, +j: U32, +seed: U32) -> Size:
  Size{U32.shrn(U32.add(Blk.side_len(i, j, 0, seed), Blk.side_len(i, j, 2, seed)), 1n),
       U32.shrn(U32.add(Blk.side_len(i, j, 3, seed), Blk.side_len(i, j, 1, seed)), 1n)}

def size_w(+s: Size) -> U32:
  match s:
    case Size{w, h}:
      w

def size_h(+s: Size) -> U32:
  match s:
    case Size{w, h}:
      h

# A share of the frame, in centimetres.
def share_cm(+total: U32, +lo: U32, +hi: U32) -> U32:
  U32.shrn(U32.mul(total, U32.sub(hi, lo)), 10n)

def rect_w(+r: Rect, +s: Size) -> U32:
  match r:
    case Rect{u0, u1, v0, v1}:
      share_cm(size_w(s), u0, u1)

def rect_h(+r: Rect, +s: Size) -> U32:
  match r:
    case Rect{u0, u1, v0, v1}:
      share_cm(size_h(s), v0, v1)

# A cut runs across the longer side, so it halves the longer one.
def cuts_wide(+r: Rect, +s: Size) -> Bool:
  U32.is_le(rect_h(r, s), rect_w(r, s))

# Where the cut lands: a third to two thirds of the way along the side it halves.
def cut_t(+i: U32, +j: U32, +p: U32, +seed: U32) -> U32:
  U32.add(370, U32.div(U32.mul(split_roll(i, j, p, seed, 1), 290), 1000))

def cut_at(+lo: U32, +hi: U32, +t: U32) -> U32:
  U32.add(lo, U32.shrn(U32.mul(U32.sub(hi, lo), t), 10n))

def cut_line(+r: Rect, +wide: Bool, +t: U32) -> U32:
  match r:
    case Rect{u0, u1, v0, v1}:
      Bool.pick(U32, wide, cut_at(u0, u1, t), cut_at(v0, v1, t))

def half_first(+r: Rect, +wide: Bool, +m: U32) -> Rect:
  match r:
    case Rect{u0, u1, v0, v1}:
      Bool.pick(Rect, wide, Rect{u0, m, v0, v1}, Rect{u0, u1, v0, m})

def half_second(+r: Rect, +wide: Bool, +m: U32) -> Rect:
  match r:
    case Rect{u0, u1, v0, v1}:
      Bool.pick(Rect, wide, Rect{m, u1, v0, v1}, Rect{u0, u1, m, v1})

def whole_rect() -> Rect:
  Rect{0, 1024, 0, 1024}

# The path's own two powers: the node below `node` on the way to `p`.
def depth_of(+p: U32) -> U32:
  Bool.pick(U32, U32.is_lt(p, 2), 0,
  Bool.pick(U32, U32.is_lt(p, 4), 1,
  Bool.pick(U32, U32.is_lt(p, 8), 2, 3)))

def pow2_of(+n: U32) -> U32:
  Bool.pick(U32, U32.is_eq(n, 0), 1, Bool.pick(U32, U32.is_eq(n, 1), 2, 4))

def node_next(+p: U32, +node: U32) -> U32:
  U32.div(p, pow2_of(U32.sub(U32.sub(depth_of(p), depth_of(node)), 1)))

# One step down the path: the rectangle of `node`'s child that lies on the way
# to p.
def rect_step(+r: Rect, +s: Size, +i: U32, +j: U32, +node: U32, +next: U32, +seed: U32) -> Rect:
  +wide = cuts_wide(r, s)
  +m = cut_line(r, wide, cut_t(i, j, node, seed))
  Bool.pick(Rect, U32.is_eq(U32.and(next, 1), 0), half_first(r, wide, m), half_second(r, wide, m))

# Exactly as many steps as the path is deep, and no more.
def rect_walk(fuel: Nat, +r: Rect, +s: Size, +i: U32, +j: U32, +p: U32, +node: U32, +seed: U32) -> Rect:
  match fuel:
    case 0n:
      r
    case 1n+f:
      +next = node_next(p, node)
      rect_walk(f, rect_step(r, s, i, j, node, next, seed), s, i, j, p, next, seed)

def rect_of(+i: U32, +j: U32, +p: U32, +seed: U32) -> Rect:
  rect_walk(U32.to_nat(depth_of(p)), whole_rect(), block_size(i, j, seed), i, j, p, 1, seed)

# ---------------------------------------------------------------------------
# What a rectangle does: cut, or stay
# ---------------------------------------------------------------------------

# The side a rectangle is cut across, in centimetres: coarser where the field
# is low. A hundred and sixty-five metres at the sparse end, sixty at the dense
# end, and each rectangle is its own factor of 0.8 to 1.3 of that, so the grain
# is not a measure.
def cut_target_cm(+d: U32, +r: U32) -> U32:
  +base = U32.sub(15000, U32.div(U32.mul(d, 95), 10))
  U32.div(U32.mul(base, U32.add(800, U32.shrn(r, 1n))), 1000)

# The narrowest side a rectangle may be cut across.
def cut_floor_cm() -> U32:
  3000

# The density is the field at the block's centre, read once for the whole tree
# of cuts that block makes: a block is smaller than the field's own grid, so
# the field barely moves across it.
def block_density(+i: U32, +j: U32, +seed: U32) -> U32:
  +c = Blk.mix_pt(Lat.site(i, j, seed), Lat.site(U32.add(i, 1), U32.add(j, 1), seed), 512)
  field_at(Lat.pt_x(c), Lat.pt_z(c), seed)

def wants_cut_in(+r: Rect, +s: Size, +d: U32, +i: U32, +j: U32, +p: U32, +seed: U32) -> Bool:
  +w = rect_w(r, s)
  +t = rect_h(r, s)
  Bool.and(Bool.not(U32.is_eq(i, Lat.river_gap())),
  Bool.and(U32.is_lt(depth_of(p), split_depth()),
  Bool.and(U32.is_le(cut_target_cm(d, split_roll(i, j, p, seed, 4)), U32.max(w, t)),
           U32.is_le(cut_floor_cm(), U32.min(w, t)))))

def cutkind_past(gang: Bool) -> SplitKind:
  match gang:
    case True{}:
      Gang{}
    case False{}:
      Through{}

def cutkind_pick(stub: Bool, gang: Bool) -> SplitKind:
  match stub:
    case True{}:
      Stub{}
    case False{}:
      cutkind_past(gang)

def cutkind_roll(+r: U32) -> SplitKind:
  cutkind_pick(U32.is_lt(r, 300), U32.is_lt(r, 520))

def cutkind_code(k: SplitKind) -> U32:
  match k:
    case Whole{}:
      0
    case Through{}:
      1
    case Gang{}:
      2
    case Stub{}:
      3

def cutkind_whole(whole: Bool, k: SplitKind) -> SplitKind:
  match whole:
    case True{}:
      Whole{}
    case False{}:
      k

def cutkind_of(+c: U32) -> SplitKind:
  cutkind_whole(U32.is_eq(c, 0), cutkind_pick(U32.is_eq(c, 3), U32.is_eq(c, 2)))

# A rectangle exists only below cuts that went through: a stub leaves its block
# in one piece. So the kind at a path is found from the block down, and the walk
# stops, as Whole, at the first node that does not carry on.
def split_if(live: Bool, +i: U32, +j: U32, +p: U32, +seed: U32) -> SplitKind:
  match live:
    case True{}:
      cutkind_roll(split_roll(i, j, p, seed, 3))
    case False{}:
      Whole{}

def code_in(+r: Rect, +s: Size, +d: U32, +i: U32, +j: U32, +node: U32, +seed: U32) -> U32:
  cutkind_code(split_if(wants_cut_in(r, s, d, i, j, node, seed), i, j, node, seed))

def code_here(+i: U32, +j: U32, +node: U32, +seed: U32) -> U32:
  code_in(rect_of(i, j, node, seed), block_size(i, j, seed), block_density(i, j, seed), i, j, node, seed)

def code_choose(done: Bool, carries: Bool, +here: U32, +deeper: U32) -> U32:
  match done:
    case True{}:
      here
    case False{}:
      Bool.pick(U32, carries, deeper, 0)

def code_walk(fuel: Nat, +i: U32, +j: U32, +p: U32, +node: U32, +seed: U32) -> U32:
  match fuel:
    case 0n:
      0
    case 1n+f:
      +here = code_here(i, j, node, seed)
      code_choose(U32.is_eq(node, p), Bool.or(U32.is_eq(here, 1), U32.is_eq(here, 2)), here,
                  code_walk(f, i, j, p, node_next(p, node), seed))

def split_code(+i: U32, +j: U32, +p: U32, +seed: U32) -> U32:
  code_walk(4n, i, j, p, 1, seed)

def split_of(+i: U32, +j: U32, +p: U32, +seed: U32) -> SplitKind:
  cutkind_of(split_code(i, j, p, seed))

# Half the carriageway, in centimetres: a lokal street, and a gang.
def split_half_cm(k: SplitKind) -> U32:
  match k:
    case Whole{}:
      0
    case Through{}:
      300
    case Gang{}:
      150
    case Stub{}:
      150

# ---------------------------------------------------------------------------
# A cut on the ground
#
# A cut is the line of constant `u` (or `v`) across its rectangle. Where an end
# of it meets one of the block's own streets, it stops at that street's
# carriageway, so the gang opens onto the road and does not lie on it; where it
# meets a cut above it, it stops at that cut's centre line, which is the same
# asphalt. A stub stops between 45% and 76% of the way across.
# ---------------------------------------------------------------------------

# The street half-width an end of the cut meets, as a share of the frame: zero
# inside the block, where the end meets another cut.
def end_trim(+edge: Bool, +half: U32, +total: U32) -> U32:
  Bool.pick(U32, edge, U32.div(U32.mul(half, 1024), U32.max(total, 1)), 0)

type Span is Data:
  Span{fixed: U32, from: U32, to: U32}

def span_of_cut(+r: Rect, +s: Size, +wide: Bool, +m: U32, +stub: Bool, +reach: U32,
                +i: U32, +j: U32) -> Span:
  match r:
    case Rect{u0, u1, v0, v1}:
      +lo = Bool.pick(U32, wide, v0, u0)
      +hi = Bool.pick(U32, wide, v1, u1)
      +total = Bool.pick(U32, wide, size_h(s), size_w(s))
      +lo_half = Bool.pick(U32, wide, Blk.south_half(i, j), Jun.half_cm(Jun.street_of(i, j, Str.South{})))
      +hi_half = Bool.pick(U32, wide, Blk.north_half(i, j), Jun.half_cm(Jun.street_of(U32.add(i, 1), j, Str.South{})))
      +from = U32.add(lo, end_trim(U32.is_eq(lo, 0), lo_half, total))
      +end = U32.sub(hi, end_trim(U32.is_eq(hi, 1024), hi_half, total))
      Span{m, from, Bool.pick(U32, stub, cut_at(lo, hi, reach), end)}

def cut_span(+i: U32, +j: U32, +p: U32, +seed: U32) -> Span:
  +r = rect_of(i, j, p, seed)
  +s = block_size(i, j, seed)
  +wide = cuts_wide(r, s)
  +reach = U32.add(460, U32.div(U32.mul(split_roll(i, j, p, seed, 5), 320), 1000))
  span_of_cut(r, s, wide, cut_line(r, wide, cut_t(i, j, p, seed)),
              U32.is_eq(split_code(i, j, p, seed), 3), reach, i, j)

# How many steps a cut is drawn in.
def cut_steps() -> U32:
  8

# A point of a cut: `fixed` across it and `t` along it.
def frame_pt(wide: Bool, +i: U32, +j: U32, +fixed: U32, +t: U32, +seed: U32) -> Lat.Pt:
  match wide:
    case True{}:
      patch(i, j, fixed, t, seed)
    case False{}:
      patch(i, j, t, fixed, seed)

# The point `k` of `cut_steps` along a cut, on the ground.
def span_point(+sp: Span, +wide: Bool, +i: U32, +j: U32, +k: U32, +seed: U32) -> Lat.Pt:
  match sp:
    case Span{fixed, from, to}:
      +t = U32.add(from, U32.div(U32.mul(U32.sub(to, from), k), cut_steps()))
      frame_pt(wide, i, j, fixed, t, seed)

def split_point(+i: U32, +j: U32, +p: U32, +k: U32, +seed: U32) -> Lat.Pt:
  span_point(cut_span(i, j, p, seed), cuts_wide(rect_of(i, j, p, seed), block_size(i, j, seed)),
             i, j, k, seed)

# ---------------------------------------------------------------------------
# The town's tally
#
# One walk down each block's cut tree, each node visited once with its
# rectangle in hand. A node counts only while every cut above it went through,
# which is the `live` flag, 1 or 0. Everything the laws ask is counted in the
# one walk and kept in one number, a byte each: the cuts that are streets,
# gangs and stubs, and the cuts that leave a half narrower than the floor. No
# point of the frame is evaluated: the walk is index arithmetic on the block's
# two sizes.
# ---------------------------------------------------------------------------

def carries(+code: U32) -> U32:
  Bool.pick(U32, Bool.or(U32.is_eq(code, 1), U32.is_eq(code, 2)), 1, 0)

def weight_of(+code: U32) -> U32:
  Bool.pick(U32, U32.is_eq(code, 1), 1,
  Bool.pick(U32, U32.is_eq(code, 2), 256,
  Bool.pick(U32, U32.is_eq(code, 3), 65536, 0)))

# Both halves of a cut keep at least this much width, so no cut leaves a sliver.
def half_floor_cm() -> U32:
  900

def narrow(+r: Rect, +s: Size) -> U32:
  Bool.pick(U32, U32.is_lt(U32.min(rect_w(r, s), rect_h(r, s)), half_floor_cm()), 1, 0)

# A block has at most seven cuts, so no byte of the tally can overflow.
def tally_node(fuel: Nat, +r: Rect, +s: Size, +d: U32, +i: U32, +j: U32, +node: U32, +seed: U32, +live: U32) -> U32:
  match fuel:
    case 0n:
      0
    case 1n+(+f):
      +code = code_in(r, s, d, i, j, node, seed)
      +wide = cuts_wide(r, s)
      +m = cut_line(r, wide, cut_t(i, j, node, seed))
      +lo = half_first(r, wide, m)
      +hi = half_second(r, wide, m)
      +below = U32.mul(live, carries(code))
      U32.add(U32.add(U32.mul(live, weight_of(code)),
                      U32.mul(U32.shln(1, 24n), U32.mul(below, U32.max(narrow(lo, s), narrow(hi, s))))),
      U32.add(tally_node(f, lo, s, d, i, j, U32.mul(node, 2), seed, below),
              tally_node(f, hi, s, d, i, j, U32.add(U32.mul(node, 2), 1), seed, below)))

def block_live(+i: U32, +j: U32) -> U32:
  Bool.pick(U32, Blk.block_exists(i, j), 1, 0)

# Blocks are the cells between nodes: cols - 1 across.
def tally_blocks(fuel: Nat, +n: U32, +seed: U32) -> U32:
  match fuel:
    case 0n:
      0
    case 1n+f:
      +i = U32.mod(n, U32.sub(Lat.cols(), 1))
      +j = U32.div(n, U32.sub(Lat.cols(), 1))
      U32.add(tally_node(3n, whole_rect(), block_size(i, j, seed), block_density(i, j, seed), i, j, 1, seed,
                         block_live(i, j)),
              tally_blocks(f, U32.add(n, 1), seed))

def town_cuts(+seed: U32) -> U32:
  tally_blocks(U32.to_nat(U32.mul(U32.sub(Lat.cols(), 1), U32.sub(Lat.rows(), 1))), 0, seed)

def cuts_through(+t: U32) -> U32:
  U32.and(t, 255)

def cuts_gang(+t: U32) -> U32:
  U32.and(U32.shrn(t, 8n), 255)

def cuts_stub(+t: U32) -> U32:
  U32.and(U32.shrn(t, 16n), 255)

def cuts_slivers(+t: U32) -> U32:
  U32.shrn(t, 24n)

# The lattice's own nodes, and two more for each cut: a T at each end of a
# side-to-side cut, a T and a dead end for a stub. Every node of degree one
# counts as a junction in the sense of the hundred-city sample.
def junctions_of(+t: U32) -> U32:
  U32.add(U32.mul(Lat.cols(), Lat.rows()),
          U32.shln(U32.add(U32.add(cuts_through(t), cuts_gang(t)), cuts_stub(t)), 1n))

def every_kind_cut(+t: U32) -> Bool:
  Bool.and(U32.is_lt(0, cuts_through(t)),
  Bool.and(U32.is_lt(0, cuts_gang(t)), U32.is_lt(0, cuts_stub(t))))

def dead_ends_in_range(+t: U32) -> Bool:
  Bool.and(U32.is_le(U32.mul(5, junctions_of(t)), U32.mul(100, cuts_stub(t))),
           U32.is_le(U32.mul(100, cuts_stub(t)), U32.mul(25, junctions_of(t))))

def split_holds(+t: U32) -> Bool:
  Bool.and(every_kind_cut(t), Bool.and(dead_ends_in_range(t), U32.is_eq(cuts_slivers(t), 0)))

# ===========================================================================
# What the cuts leave standing
#
# A cut is a street, and a lot cannot stand on a street. A lot, a prop or a
# tree is built only if it keeps clear of every cut in its block by the cut's
# half carriageway and a pavement. The frontage rows still run along the
# lattice streets and the core grid still fills the middle; where a cut
# crosses either, the cells it touches are left out and the street is the gap.
# ===========================================================================

# Whether the point (px, pz) is at least `r` from the segment a to b. Wrapped
# differences are two's complement, so a product of them is the signed product
# and the sign is the top bit; every product stays under 2^31 at the size of a
# block. A point past either end is measured from that end.
def seg_clear(+px: U32, +pz: U32, +a: Lat.Pt, +b: Lat.Pt, +r: U32) -> Bool:
  match a:
    case Lat.Pt{+ax, +az}:
      match b:
        case Lat.Pt{+bx, +bz}:
          +ex = U32.sub(bx, ax)
          +ez = U32.sub(bz, az)
          +dx = U32.sub(px, ax)
          +dz = U32.sub(pz, az)
          +fx = U32.sub(px, bx)
          +fz = U32.sub(pz, bz)
          +along = U32.add(U32.mul(dx, ex), U32.mul(dz, ez))
          +wide = U32.add(U32.mul(ex, ex), U32.mul(ez, ez))
          +cross = Blk.mag_of(U32.sub(U32.mul(dx, ez), U32.mul(dz, ex)))
          +near_a = U32.add(U32.mul(dx, dx), U32.mul(dz, dz))
          +near_b = U32.add(U32.mul(fx, fx), U32.mul(fz, fz))
          +beside = U32.div(cross, U32.max(Blk.sqrt(wide), 1))
          +r2 = U32.mul(r, r)
          Bool.pick(Bool, U32.is_gt(along, 2147483647), U32.is_le(r2, near_a),
          Bool.pick(Bool, U32.is_lt(wide, along), U32.is_le(r2, near_b),
                    U32.is_le(r, beside)))

# A cut on the ground is a curve, so a point is measured against it as four
# chords, a quarter of the cut each. A chord of a quarter of a block strays less
# than half a metre from the curve it stands for.
def cut_path_from(fuel: Nat, +sp: Span, +wide: Bool, +i: U32, +j: U32, +k: U32, +seed: U32) -> +List<Lat.Pt>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+f:
      span_point(sp, wide, i, j, k, seed) <> cut_path_from(f, sp, wide, i, j, U32.add(k, 2), seed)

def cut_path(+i: U32, +j: U32, +p: U32, +seed: U32) -> +List<Lat.Pt>:
  cut_path_from(5n, cut_span(i, j, p, seed), cuts_wide(rect_of(i, j, p, seed), block_size(i, j, seed)),
                i, j, 0, seed)

def path_clear(+pts: +List<Lat.Pt>, +px: U32, +pz: U32, +r: U32) -> Bool:
  match pts:
    case Nil{}:
      True{}
    case +a <> +rest:
      match rest:
        case Nil{}:
          True{}
        case +b <> +more:
          Bool.and(seg_clear(px, pz, a, b, r), path_clear(b <> more, px, pz, r))

# A lot is clear of a cut when its centre and its four corners are.
def lot_off(l: Blk.Lot, +pts: +List<Lat.Pt>, +r: U32) -> Bool:
  match l:
    case Blk.Lot{x, z, fx, fz, w, d, kind, ax, az, bx, bz, cx, cz, dx, dz}:
      Bool.and(path_clear(pts, x, z, r),
      Bool.and(path_clear(pts, ax, az, r),
      Bool.and(path_clear(pts, bx, bz, r),
      Bool.and(path_clear(pts, cx, cz, r), path_clear(pts, dx, dz, r)))))

def cut_reach_cm(+code: U32) -> U32:
  U32.add(split_half_cm(cutkind_of(code)), Blk.pavement_cm())

# Walks the block's seven cut slots, and answers for the lot against each cut
# that exists.
def lot_clear_from(fuel: Nat, +p: U32, +l: Blk.Lot, +i: U32, +j: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+(+f):
      +code = split_code(i, j, p, seed)
      Bool.and(Bool.or(U32.is_eq(code, 0), lot_off(l, cut_path(i, j, p, seed), cut_reach_cm(code))),
               lot_clear_from(f, U32.add(p, 1), l, i, j, seed))

def lot_clear(+l: Blk.Lot, +i: U32, +j: U32, +seed: U32) -> Bool:
  lot_clear_from(7n, 1, l, i, j, seed)

def point_clear_from(fuel: Nat, +p: U32, +px: U32, +pz: U32, +i: U32, +j: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+(+f):
      +code = split_code(i, j, p, seed)
      Bool.and(Bool.or(U32.is_eq(code, 0), path_clear(cut_path(i, j, p, seed), px, pz, cut_reach_cm(code))),
               point_clear_from(f, U32.add(p, 1), px, pz, i, j, seed))

def prop_clear(p: Pav.Prop, +i: U32, +j: U32, +seed: U32) -> Bool:
  match p:
    case Pav.Prop{x, z, r, kind}:
      point_clear_from(7n, 1, x, z, i, j, seed)

# What is built: a frontage lot, the prop in front of it, a core cell and the
# tree in a kebun are each left out where a cut runs through them.
def lot_built(+i: U32, +j: U32, +side: U32, +ring: U32, +t: U32, +seed: U32) -> Bool:
  lot_clear(Blk.lot_at(i, j, side, ring, t, seed), i, j, seed)

def prop_built(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Bool:
  Bool.and(lot_built(i, j, side, 0, t, seed), prop_clear(Pav.prop_at(i, j, side, t, seed), i, j, seed))

def core_lot_built(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Bool:
  lot_clear(Blk.core_lot_at(i, j, a, b, seed), i, j, seed)

def core_tree_built(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Bool:
  prop_clear(Pav.core_tree(i, j, a, b, seed), i, j, seed)
