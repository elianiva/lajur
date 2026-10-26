# lajur — the lokal streets the car can drive.
#
# A tree block's streets (world.bend) meet at shared points: a branch starts
# on a point of its parent, a link ends on one, a trunk starts where its
# mouth ends. Split at every point where a street starts or ends, the
# streets become ways between junctions, and a car on one picks the next at
# each junction. The network is a function of the block alone, so the game
# makes it once, when the car turns in.
#
# Units are those of world.bend: centimetres, a curve parameter in 65536ths,
# headings in 65536ths of a turn from +x toward +z.
import Base
import ./world.bend as W

# Where a way's first end meets a road: a road of the lattice, by its key,
# its parameter there, and the centimetres along it from its key crossing; or
# the collector across cell (i, j), across u or across v, at its parameter
# t. A mouth onto any other edge meets no road the route can take.
type Kerb is Data:
  Inside{}
  Kerb{i: U32, j: U32, east: Bool, t: U32, at: U32}
  OnCut{i: U32, j: U32, u: Bool, t: U32}

# A way runs from a to b, both in the block's frame, so junctions match
# exactly; its points are on the ground, a to b. ha is the heading leaving a
# into the way, hb the heading leaving b into it.
type Way is Data:
  Way{a: W.Pt, b: W.Pt, pts: List<&2, W.Pt>, length: U32, ha: U32, hb: U32, kerb: Kerb}

# A place to turn in: centimetres along the leg, on which side, and the
# block's cell, its place among the cell's blocks, and the mouth's kerb. A
# gate is the mouth of a collector inside cell (ci, cj), entered toward dir.
type Door is Data:
  Door{at: U32, left: Bool, ci: U32, cj: U32, blk: U32, p: W.Pt}
  Gate{at: U32, left: Bool, ci: U32, cj: U32, dir: U32}

def same(+p: W.Pt, +q: W.Pt) -> Bool:
  Bool.and(U32.is_eq(W.pt_x(p), W.pt_x(q)), U32.is_eq(W.pt_z(p), W.pt_z(q)))

def member(ns: List<&2, W.Pt>, +p: W.Pt) -> Bool:
  match ns:
    case Nil{}:
      False{}
    case Con{+q, r}:
      Bool.or(same(q, p), member(r, p))

def first(ps: List<&2, W.Pt>) -> W.Pt:
  W.pt_head(ps, W.Pt{0, 0})

def last(ps: List<&2, W.Pt>) -> W.Pt:
  W.pt_head(List.reverse(&2, W.Pt, ps), W.Pt{0, 0})

def second(+ps: List<&2, W.Pt>) -> W.Pt:
  W.nth(ps, 1, first(ps))

def heading(+p: W.Pt, +q: W.Pt) -> U32:
  W.atan2(U32.sub(W.pt_z(q), W.pt_z(p)), U32.sub(W.pt_x(q), W.pt_x(p)))

def turned(+h: U32) -> U32:
  U32.and(U32.add(h, 32768), 65535)

# ---- Measuring along a road ---------------------------------------------------

# Centimetres along a curve to parameter t, by the same 32 chords that measure
# the road, the one across t cut short there; past t every chord is empty.
def chords_to(fuel: Nat, +k: W.Curve, +step: U32, +t: U32, +prev: W.Pt, +acc: U32) -> U32:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +s1 = U32.mul(U32.add(step, 1), 2048)
      +q = W.curve_at(k, U32.min(s1, t))
      chords_to(p, k, U32.add(step, 1), t, q, U32.add(acc, W.dist(prev, q)))

def length_to(+k: W.Curve, +t: U32) -> U32:
  chords_to(32n, k, 0, t, W.curve_at(k, 0), 0)

def kerb_on(here: Bool, +seed: U32, +i: U32, +j: U32, +east: Bool, +t: U32) -> Kerb:
  match here:
    case False{}:
      Inside{}
    case True{}:
      Kerb{i, j, east, t, length_to(W.curve_of(seed, i, j, east), t)}

# A mouth starts on the block's outer edge. On a side of the block that is a
# side of the cell, that is a road of the lattice: south and north run east
# along u, west and east run south along v.
def road_kerb(+seed: U32, +i: U32, +j: U32, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +f: W.Frame, +p: W.Pt) -> Kerb:
  +mu = W.frame_mu(f)
  +mv = W.frame_mv(f)
  +x = W.pt_x(p)
  +z = W.pt_z(p)
  +s = Bool.and(U32.is_eq(v0, 0), U32.is_eq(z, 0))
  +n = Bool.and(U32.is_eq(v1, 65536), U32.is_eq(z, W.mul16(mv, 65536)))
  +w = Bool.and(U32.is_eq(u0, 0), U32.is_eq(x, 0))
  +e = Bool.and(U32.is_eq(u1, 65536), U32.is_eq(x, W.mul16(mu, 65536)))
  +ki = Bool.pick(U32, e, U32.add(i, 1), i)
  +kj = Bool.pick(U32, n, U32.add(j, 1), j)
  +east = Bool.or(s, n)
  +t = Bool.pick(U32, east, W.frac16(x, mu), W.frac16(z, mv))
  kerb_on(Bool.and(Bool.or(east, Bool.or(w, e)), W.has_road(seed, ki, kj, east)), seed, ki, kj, east, t)

def cut_kerb(on: Bool, +u: Bool, +seed: U32, +i: U32, +j: U32, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +f: W.Frame, +p: W.Pt) -> Kerb:
  match on:
    case True{}:
      OnCut{i, j, u, Bool.pick(U32, u, W.frac16(W.pt_z(p), W.frame_mv(f)), W.frac16(W.pt_x(p), W.frame_mu(f)))}
    case False{}:
      road_kerb(seed, i, j, u0, u1, v0, v1, f, p)

# On a side of the block that is a collector of the cell, the kerb is on it.
def kerb_of(+seed: U32, +i: U32, +j: U32, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +f: W.Frame, +p: W.Pt) -> Kerb:
  +c = W.cell_cuts(seed, i, j)
  +uc = W.cuts_u(c)
  +vc = W.cuts_v(c)
  +on_u = Bool.and(U32.is_ne(uc, 0), Bool.and(Bool.or(U32.is_eq(u0, uc), U32.is_eq(u1, uc)),
          U32.is_eq(W.pt_x(p), W.mul16(W.frame_mu(f), uc))))
  +on_v = Bool.and(U32.is_ne(vc, 0), Bool.and(Bool.or(U32.is_eq(v0, vc), U32.is_eq(v1, vc)),
          U32.is_eq(W.pt_z(p), W.mul16(W.frame_mv(f), vc))))
  cut_kerb(Bool.or(on_u, on_v), on_u, seed, i, j, u0, u1, v0, v1, f, p)

def kerb_if(mouth: Bool, +seed: U32, +i: U32, +j: U32, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +f: W.Frame, +p: W.Pt) -> Kerb:
  match mouth:
    case False{}:
      Inside{}
    case True{}:
      kerb_of(seed, i, j, u0, u1, v0, v1, f, p)

# ---- The network --------------------------------------------------------------

# Every point where a street starts or ends: the junctions.
def ends(ss: List<&2, W.Street>, acc: List<&2, W.Pt>) -> List<&2, W.Pt>:
  match ss:
    case Nil{}:
      acc
    case Con{s, r}:
      match s:
        case W.Street{tag, bulb, +pts}:
          ends(r, first(pts) <> last(pts) <> acc)

# A street cut at every junction inside it, as runs of points, each from one
# junction to the next.
def split(ps: List<&2, W.Pt>, +ns: List<&2, W.Pt>, +cur: List<&2, W.Pt>, +acc: List<&2, List<&2, W.Pt>>) -> List<&2, List<&2, W.Pt>>:
  match ps:
    case Nil{}:
      List.reverse(&2, W.Pt, cur) <> acc
    case Con{+p, +r}:
      +at = Bool.and(member(ns, p), Bool.not(List.is_empty(&2, W.Pt, r)))
      +cur2 = {p <> cur : List<&2, W.Pt>}
      split(r, ns, Bool.pick(List<&2, W.Pt>, at, [p], cur2),
        Bool.pick(List<&2, List<&2, W.Pt>>, at, List.reverse(&2, W.Pt, cur2) <> acc, acc))

def polylen(ps: List<&2, W.Pt>, +prev: W.Pt, +acc: U32) -> U32:
  match ps:
    case Nil{}:
      acc
    case Con{+q, r}:
      polylen(r, q, U32.add(acc, W.dist(prev, q)))

def way_of(+run: List<&2, W.Pt>, +f: W.Frame, +kerb: Kerb) -> Way:
  +g = W.street_world(run, f)
  +back = List.reverse(&2, W.Pt, g)
  Way{first(run), last(run), g, polylen(g, first(g), 0), heading(first(g), second(g)),
      heading(first(back), second(back)), kerb}

def ways_of(runs: List<&2, List<&2, W.Pt>>, +f: W.Frame, +kerb: Kerb, acc: List<&2, Way>) -> List<&2, Way>:
  match runs:
    case Nil{}:
      acc
    case Con{+run, r}:
      ways_of(r, f, kerb, way_of(run, f, kerb) <> acc)

def street_ways(ss: List<&2, W.Street>, +ns: List<&2, W.Pt>, +seed: U32, +i: U32, +j: U32, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +f: W.Frame, acc: List<&2, Way>) -> List<&2, Way>:
  match ss:
    case Nil{}:
      acc
    case Con{s, r}:
      match s:
        case W.Street{+tag, bulb, +pts}:
          +kerb = kerb_if(U32.is_eq(tag, 2), seed, i, j, u0, u1, v0, v1, f, first(pts))
          +tail = List.drop(&2, W.Pt, pts, 1n)
          street_ways(r, ns, seed, i, j, u0, u1, v0, v1, f,
            ways_of(split(tail, ns, [first(pts)], Nil{}), f, kerb, acc))

def land_code_of(+x: W.Fill) -> U32:
  match x:
    case W.Fill{land, court, ring, streets, mouths, linked, bulb, thru}:
      land

# A tree block's streets; any other block has none the car can drive.
def tree_streets(+x: W.Fill) -> List<&2, W.Street>:
  Bool.pick(List<&2, W.Street>, U32.is_eq(land_code_of(x), 2), W.fill_streets(x), Nil{})

# The ways of a block of cell (i, j).
def net_of(+seed: U32, +i: U32, +j: U32, b: W.Blk) -> List<&2, Way>:
  match b:
    case W.Blk{+u0, +u1, +v0, +v1, d, sr, nr, wr, er, +fill}:
      +ss = tree_streets(fill)
      street_ways(ss, ends(ss, Nil{}), seed, i, j, u0, u1, v0, v1, W.frame_of(seed, i, j), Nil{})

def net_in(bs: List<&2, W.Blk>, +k: U32, +seed: U32, +i: U32, +j: U32) -> List<&2, Way>:
  match bs:
    case Nil{}:
      Nil{}
    case Con{b, r}:
      match k:
        case 0:
          net_of(seed, i, j, b)
        case _:
          net_in(r, U32.sub(k, 1), seed, i, j)

# The ways of the k-th block of cell (i, j).
def net_at(+seed: U32, +i: U32, +j: U32, +k: U32) -> List<&2, Way>:
  net_in(W.cell_blocks(seed, i, j), k, seed, i, j)

# ---- Doors ---------------------------------------------------------------------

def way_a(+w: Way) -> W.Pt:
  match w:
    case Way{a, b, pts, length, ha, hb, kerb}:
      a

def way_kerb(+w: Way) -> Kerb:
  match w:
    case Way{a, b, pts, length, ha, hb, kerb}:
      kerb

def kerb_here(+kb: Kerb, +ki: U32, +kj: U32, +east: Bool) -> Bool:
  match kb:
    case Inside{}:
      False{}
    case Kerb{i, j, e, t, at}:
      Bool.and(Bool.and(U32.is_eq(i, ki), U32.is_eq(j, kj)), Bool.not(Bool.xor(e, east)))
    case OnCut{i, j, u, t}:
      False{}

def kerb_at(+kb: Kerb) -> U32:
  match kb:
    case Inside{}:
      0
    case Kerb{i, j, e, t, at}:
      at
    case OnCut{i, j, u, t}:
      0

# A mouth street of a block makes a door on the road (ki, kj, east) when its
# kerb is on that road. `length` is the road's, `fwd` whether the car runs
# the road's own way, `left` whether this cell is on the car's left.
def mouth_doors(ss: List<&2, W.Street>, +seed: U32, +i: U32, +j: U32, +k: U32, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +f: W.Frame,
                +ki: U32, +kj: U32, +east: Bool, +length: U32, +fwd: Bool, +left: Bool, +acc: List<&2, Door>) -> List<&2, Door>:
  match ss:
    case Nil{}:
      acc
    case Con{s, r}:
      match s:
        case W.Street{+tag, bulb, +pts}:
          +p = first(pts)
          +kb = kerb_if(U32.is_eq(tag, 2), seed, i, j, u0, u1, v0, v1, f, p)
          +on = kerb_here(kb, ki, kj, east)
          +at = kerb_at(kb)
          mouth_doors(r, seed, i, j, k, u0, u1, v0, v1, f, ki, kj, east, length, fwd, left,
            Bool.pick(List<&2, Door>, on, Door{Bool.pick(U32, fwd, at, U32.sub(length, U32.min(at, length))), left, i, j, k, p} <> acc, acc))

def block_doors(bs: List<&2, W.Blk>, +k: U32, +seed: U32, +i: U32, +j: U32, +f: W.Frame, +ki: U32, +kj: U32, +east: Bool,
                +length: U32, +fwd: Bool, +left: Bool, acc: List<&2, Door>) -> List<&2, Door>:
  match bs:
    case Nil{}:
      acc
    case Con{b, r}:
      match b:
        case W.Blk{+u0, +u1, +v0, +v1, d, sr, nr, wr, er, +fill}:
          +ss = tree_streets(fill)
          block_doors(r, U32.add(k, 1), seed, i, j, f, ki, kj, east, length, fwd, left,
            mouth_doors(ss, seed, i, j, k, u0, u1, v0, v1, f, ki, kj, east, length, fwd, left, acc))

def cell_doors(+seed: U32, +i: U32, +j: U32, +ki: U32, +kj: U32, +east: Bool, +length: U32, +fwd: Bool, +left: Bool, acc: List<&2, Door>) -> List<&2, Door>:
  block_doors(W.cell_blocks(seed, i, j), 0, seed, i, j, W.frame_of(seed, i, j), ki, kj, east, length, fwd, left, acc)

# The doors on the road (ki, kj, east) for a car running it `fwd` (east or
# south) or back: the cell south of an east road, or east of a south road,
# is on the car's left when it runs the road back; the other cell when it
# runs it forward.
def doors_of(+seed: U32, +ki: U32, +kj: U32, +east: Bool, +length: U32, +fwd: Bool) -> List<&2, Door>:
  +own = Bool.pick(Bool, east, Bool.not(fwd), fwd)
  +oi = Bool.pick(U32, east, ki, U32.sub(ki, 1))
  +oj = Bool.pick(U32, east, U32.sub(kj, 1), kj)
  cell_doors(seed, ki, kj, ki, kj, east, length, fwd, own,
    cell_doors(seed, oi, oj, ki, kj, east, length, fwd, Bool.not(own), Nil{}))

def none_t() -> U32:
  4294967295

# The parameter of a kerb on the collector across u (or v) of this cell,
# strictly between lo and hi, or none.
def cut_t(+kb: Kerb, +across_u: Bool, +lo: U32, +hi: U32) -> U32:
  match kb:
    case Inside{}:
      none_t()
    case Kerb{i, j, e, t, at}:
      none_t()
    case OnCut{i, j, u, +t}:
      Bool.pick(U32, Bool.and(Bool.not(Bool.xor(u, across_u)), Bool.and(U32.is_lt(lo, t), U32.is_lt(t, hi))), t, none_t())

def cut_door(on: Bool, +t: U32, +f: W.Frame, +across_u: Bool, +fixed: U32, +l0: U32, +left: Bool,
             +i: U32, +j: U32, +k: U32, +p: W.Pt, acc: List<&2, Door>) -> List<&2, Door>:
  match on:
    case False{}:
      acc
    case True{}:
      +l = W.frame_to(f, across_u, fixed, t)
      Door{U32.sub(U32.max(l, l0), U32.min(l, l0)), left, i, j, k, p} <> acc

def cut_mouths(ss: List<&2, W.Street>, +seed: U32, +i: U32, +j: U32, +k: U32, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +f: W.Frame,
               +across_u: Bool, +fixed: U32, +lo: U32, +hi: U32, +l0: U32, +left: Bool, acc: List<&2, Door>) -> List<&2, Door>:
  match ss:
    case Nil{}:
      acc
    case Con{s, r}:
      match s:
        case W.Street{+tag, bulb, +pts}:
          +p = first(pts)
          +t = cut_t(kerb_if(U32.is_eq(tag, 2), seed, i, j, u0, u1, v0, v1, f, p), across_u, lo, hi)
          cut_mouths(r, seed, i, j, k, u0, u1, v0, v1, f, across_u, fixed, lo, hi, l0, left,
            cut_door(U32.is_ne(t, none_t()), t, f, across_u, fixed, l0, left, i, j, k, p, acc))

# A block on the side of the collector where u (or v) grows is on the car's
# left when `flip` is false.
def cut_blocks(bs: List<&2, W.Blk>, +k: U32, +seed: U32, +i: U32, +j: U32, +f: W.Frame, +across_u: Bool, +fixed: U32,
               +lo: U32, +hi: U32, +l0: U32, +flip: Bool, acc: List<&2, Door>) -> List<&2, Door>:
  match bs:
    case Nil{}:
      acc
    case Con{b, r}:
      match b:
        case W.Blk{+u0, +u1, +v0, +v1, d, sr, nr, wr, er, +fill}:
          +grows = U32.is_eq(Bool.pick(U32, across_u, u0, v0), fixed)
          cut_blocks(r, U32.add(k, 1), seed, i, j, f, across_u, fixed, lo, hi, l0, flip,
            cut_mouths(tree_streets(fill), seed, i, j, k, u0, u1, v0, v1, f, across_u, fixed, lo, hi, l0,
                       Bool.xor(grows, flip), acc))

# The doors on the collector of cell (i, j) across u (or v) at `fixed`, for a
# car running it from t0 to t1: centimetres from t0.
def cut_doors(+seed: U32, +i: U32, +j: U32, +across_u: Bool, +fixed: U32, +t0: U32, +t1: U32, +flip: Bool) -> List<&2, Door>:
  +f = W.frame_of(seed, i, j)
  cut_blocks(W.cell_blocks(seed, i, j), 0, seed, i, j, f, across_u, fixed, U32.min(t0, t1), U32.max(t0, t1),
             W.frame_to(f, across_u, fixed, t0), flip, Nil{})

# ---- Driving the network ---------------------------------------------------------

def no_way() -> Way:
  Way{W.Pt{0, 0}, W.Pt{0, 0}, Nil{}, 0, 0, 0, Inside{}}

def nth_way(net: List<&2, Way>, +k: U32) -> Way:
  Maybe.default(&2, Way, List.get(&2, Way, net, U32.to_nat(k)), no_way())

def way_length(+w: Way) -> U32:
  match w:
    case Way{a, b, pts, length, ha, hb, kerb}:
      length

def length_at(net: List<&2, Way>, +k: U32) -> U32:
  way_length(nth_way(net, k))

def none() -> U32:
  4294967295

# The first way that starts at p: the way in from a mouth's kerb.
def way_from(net: List<&2, Way>, +p: W.Pt, +k: U32, +found: U32) -> U32:
  match net:
    case Nil{}:
      found
    case Con{+w, r}:
      +take = Bool.and(same(way_a(w), p), U32.is_eq(found, none()))
      way_from(r, p, U32.add(k, 1), Bool.pick(U32, take, k, found))

# The ways leaving a junction, sorted by the turn onto them: left, straight
# on (within 45 degrees) and right, the first of each, and which way along
# it the car would run.
type Choice is Data:
  Choice{lo: Bool, li: U32, lf: Bool, so: Bool, si: U32, sf: Bool, ro: Bool, ri: U32, rf: Bool}

def no_choice() -> Choice:
  Choice{False{}, 0, True{}, False{}, 0, True{}, False{}, 0, True{}}

def take(c: Choice, +here: Bool, +straight: Bool, +right: Bool, +k: U32, +f: Bool) -> Choice:
  match c:
    case Choice{+lo, +li, +lf, +so, +si, +sf, +ro, +ri, +rf}:
      +tl = Bool.and(Bool.and(here, Bool.not(straight)), Bool.and(Bool.not(right), Bool.not(lo)))
      +ts = Bool.and(Bool.and(here, straight), Bool.not(so))
      +tr = Bool.and(Bool.and(here, Bool.not(straight)), Bool.and(right, Bool.not(ro)))
      Choice{Bool.or(lo, tl), Bool.pick(U32, tl, k, li), Bool.pick(Bool, tl, f, lf),
             Bool.or(so, ts), Bool.pick(U32, ts, k, si), Bool.pick(Bool, ts, f, sf),
             Bool.or(ro, tr), Bool.pick(U32, tr, k, ri), Bool.pick(Bool, tr, f, rf)}

# A heading turned clockwise from the +x axis toward +z is a turn to the
# right, seen from above.
def choices(net: List<&2, Way>, +k: U32, +skip: U32, +node: W.Pt, +arr: U32, c: Choice) -> Choice:
  match net:
    case Nil{}:
      c
    case Con{w, r}:
      match w:
        case Way{+a, +b, pts, length, +ha, +hb, kerb}:
          +at_a = same(a, node)
          +here = Bool.and(Bool.or(at_a, same(b, node)), U32.is_ne(k, skip))
          +t = W.turn_from(Bool.pick(U32, at_a, ha, hb), arr)
          choices(r, U32.add(k, 1), skip, node, arr,
            take(c, here, U32.is_lt(W.sabs(t), 8192), W.slt(0, t), k, at_a))

# The car reaches the end of a way: where it is (a mouth's kerb, or a
# junction), the heading it arrives with, and the ways it may take on.
type Arrival is Data:
  Arrival{out: Kerb, arr: U32, c: Choice}

def arrive_on(w: Way, +net: List<&2, Way>, +way: U32, +fwd: Bool) -> Arrival:
  match w:
    case Way{+a, +b, pts, length, +ha, +hb, +kerb}:
      +node = Bool.pick(W.Pt, fwd, b, a)
      +arr = turned(Bool.pick(U32, fwd, hb, ha))
      Arrival{Bool.pick(Kerb, fwd, Inside{}, kerb), arr, choices(net, 0, way, node, arr, no_choice())}

def arrive(+net: List<&2, Way>, +way: U32, +fwd: Bool) -> Arrival:
  arrive_on(nth_way(net, way), net, way, fwd)

def is_kerb(+k: Kerb) -> Bool:
  match k:
    case Inside{}:
      False{}
    case Kerb{i, j, e, t, at}:
      True{}
    case OnCut{i, j, u, t}:
      True{}

def door_cm(+d: Door) -> U32:
  match d:
    case Door{at, l, ci, cj, blk, p}:
      at
    case Gate{at, l, ci, cj, dir}:
      at

def door_left(+d: Door) -> Bool:
  match d:
    case Door{at, l, ci, cj, blk, p}:
      l
    case Gate{at, l, ci, cj, dir}:
      l

# The door at `at` on the chosen side.
def door_is(+d: Door, +at: U32, +left: Bool) -> Bool:
  Bool.and(U32.is_eq(door_cm(d), at), Bool.not(Bool.xor(door_left(d), left)))

def door_at(ds: List<&2, Door>, +at: U32, +left: Bool, +found: Door) -> Door:
  match ds:
    case Nil{}:
      found
    case Con{+d, r}:
      door_at(r, at, left, Bool.pick(Door, door_is(d, at, left), d, found))
