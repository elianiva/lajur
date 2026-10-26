# lajur — layer 4 of the world: what stands on each cell.
#
# A cell's roads and blocks become placements: a lot for each building, the
# civic courts inside ring blocks, and big round canopies (mangga, beringin,
# flamboyan, bambu) wherever land is left. Everything is a function of
# (seed, i, j), and every placement stays inside its own cell's blocks, so
# cells stay order-free and never overlap.
#
# Positions are metres as F32, measured from the cell's first corner, so a
# cell far from the origin keeps its precision. Only the IEEE operations that
# round the same way on every target are used: no sine, cosine or arc
# tangent. Rolls are a hash's top 24 bits, as a fraction.
import Base
import ./world.bend as W

# ===========================================================================
# Points and rolls
# ===========================================================================

type V is Data:
  V{x: F32, z: F32}

def vx(+p: V) -> F32:
  match p:
    case V{x, z}:
      x

def vz(+p: V) -> F32:
  match p:
    case V{x, z}:
      z

def f32(+n: U32) -> F32:
  F32.from_nat(U32.to_nat(n))

# Signed centimetres to metres.
def metres(+cm: U32) -> F32:
  Bool.pick(F32, W.is_neg(cm), F32.neg((f32(W.sabs(cm)) / 100.0 : F32)), (f32(cm) / 100.0 : F32))

# A point of the world, centimetres, from the cell's first corner.
def local(+o: W.Pt, +p: W.Pt) -> V:
  V{metres(U32.sub(W.pt_x(p), W.pt_x(o))), metres(U32.sub(W.pt_z(p), W.pt_z(o)))}

def roll(+h: U32) -> F32:
  (f32(U32.shrn(h, 8n)) / 16777216.0 : F32)

def r2(+k: U32, +a: U32, +b: U32) -> F32:
  roll(W.mix(W.mix(k, a), b))

def r3(+k: U32, +a: U32, +b: U32, +c: U32) -> F32:
  roll(W.mix(W.mix(W.mix(k, a), b), c))

def r4(+k: U32, +a: U32, +b: U32, +c: U32, +d: U32) -> F32:
  roll(W.mix(W.mix(W.mix(W.mix(k, a), b), c), d))

def lerp(+a: F32, +b: F32, +t: F32) -> F32:
  (a + (b - a) * t : F32)

# A nonnegative F32 rounded down, as a U32.
def floor_u(+x: F32) -> U32:
  F32.to_u32(F32.floor(F32.max(x, 0.0)))

def hypot(+x: F32, +z: F32) -> F32:
  F32.sqrt((x * x + z * z : F32))

def dist(+p: V, +q: V) -> F32:
  hypot((vx(q) - vx(p) : F32), (vz(q) - vz(p) : F32))

# ===========================================================================
# Polygons
# ===========================================================================

def last_v(ps: List<&2, V>, +d: V) -> V:
  Maybe.default(&2, V, List.last(&2, V, ps), d)

def crosses(+p: V, +a: V, +b: V) -> Bool:
  match p:
    case V{px, pz}:
      match a:
        case V{ax, az}:
          match b:
            case V{bx, bz}:
              Bool.and(Bool.xor((az > pz : F32), (bz > pz : F32)), (px < (bx - ax) * (pz - az) / (bz - az) + ax : F32))

def in_go(ps: List<&2, V>, +p: V, +prev: V, +inside: Bool) -> Bool:
  match ps:
    case Nil{}:
      inside
    case Con{+q, r}:
      in_go(r, p, q, Bool.xor(inside, crosses(p, q, prev)))

def in_poly(+p: V, +poly: List<&2, V>) -> Bool:
  in_go(poly, p, last_v(poly, p), False{})

# The squared distance from p to the segment ab.
def point_seg2(+p: V, +a: V, +b: V) -> F32:
  match p:
    case V{px, pz}:
      match a:
        case V{ax, az}:
          match b:
            case V{bx, bz}:
              +dx = (bx - ax : F32)
              +dz = (bz - az : F32)
              +l = (dx * dx + dz * dz : F32)
              +num = ((px - ax) * dx + (pz - az) * dz : F32)
              +t = F32.clamp(F32.div(num, F32.max(l, 0.000001)), 0.0, 1.0)
              +ex = (px - ax - t * dx : F32)
              +ez = (pz - az - t * dz : F32)
              (ex * ex + ez * ez : F32)

def cross3(+o: V, +a: V, +b: V) -> F32:
  ((vx(a) - vx(o)) * (vz(b) - vz(o)) - (vz(a) - vz(o)) * (vx(b) - vx(o)) : F32)

# The squared distance between two segments; 0 where they cross.
def seg_far(hit: Bool, +a: V, +b: V, +c: V, +d: V) -> F32:
  match hit:
    case True{}:
      0.0
    case False{}:
      F32.min(F32.min(point_seg2(a, c, d), point_seg2(b, c, d)), F32.min(point_seg2(c, a, b), point_seg2(d, a, b)))

def seg_seg2(+a: V, +b: V, +c: V, +d: V) -> F32:
  seg_far(Bool.and((cross3(c, d, a) * cross3(c, d, b) < 0.0 : F32), (cross3(a, b, c) * cross3(a, b, d) < 0.0 : F32)), a, b, c, d)

def edges_seg(ps: List<&2, V>, +prev: V, +a: V, +b: V, +best: F32) -> F32:
  match ps:
    case Nil{}:
      best
    case Con{+q, r}:
      edges_seg(r, q, a, b, F32.min(best, seg_seg2(a, b, prev, q)))

# The distance from a polygon to a segment; 0 where the segment starts inside.
# Each candidate is squared and the root taken once, which picks the same
# value as the least of the roots.
def poly_far(inside: Bool, +poly: List<&2, V>, +a: V, +b: V) -> F32:
  match inside:
    case True{}:
      0.0
    case False{}:
      F32.sqrt(edges_seg(poly, last_v(poly, a), a, b, 1000000000000.0))

def poly_seg(+poly: List<&2, V>, +a: V, +b: V) -> F32:
  poly_far(in_poly(a, poly), poly, a, b)

type Span is Data:
  Span{lo: F32, hi: F32}

def project(ps: List<&2, V>, +nx: F32, +nz: F32, +lo: F32, +hi: F32) -> Span:
  match ps:
    case Nil{}:
      Span{lo, hi}
    case Con{+q, r}:
      +s = (vx(q) * nx + vz(q) * nz : F32)
      project(r, nx, nz, F32.min(lo, s), F32.max(hi, s))

def apart(sa: Span, sb: Span, +gap: F32) -> Bool:
  match sa:
    case Span{a0, a1}:
      match sb:
        case Span{b0, b1}:
          Bool.or((a1 + gap <= b0 : F32), (b1 + gap <= a0 : F32))

# Whether an edge of `es` is an axis that separates the two polygons.
def separates(es: List<&2, V>, +prev: V, +pa: List<&2, V>, +pb: List<&2, V>, +gap: F32) -> Bool:
  match es:
    case Nil{}:
      False{}
    case Con{+q, r}:
      +nx = (vz(q) - vz(prev) : F32)
      +nz = (vx(prev) - vx(q) : F32)
      +l = F32.max(hypot(nx, nz), 0.000001)
      +ux = (nx / l : F32)
      +uz = (nz / l : F32)
      Bool.or(apart(project(pa, ux, uz, 1000000.0, F32.neg(1000000.0)), project(pb, ux, uz, 1000000.0, F32.neg(1000000.0)), gap),
        separates(r, q, pa, pb, gap))

# Two convex polygons overlap, by separating axes, with a small gap allowed.
def overlap(+pa: List<&2, V>, +pb: List<&2, V>) -> Bool:
  Bool.not(Bool.or(separates(pa, last_v(pa, V{0.0, 0.0}), pa, pb, 0.3), separates(pb, last_v(pb, V{0.0, 0.0}), pa, pb, 0.3)))

type Box is Data:
  Box{x0: F32, z0: F32, x1: F32, z1: F32}

def box_go(ps: List<&2, V>, +b: Box) -> Box:
  match ps:
    case Nil{}:
      b
    case Con{+q, r}:
      match b:
        case Box{x0, z0, x1, z1}:
          box_go(r, Box{F32.min(x0, vx(q)), F32.min(z0, vz(q)), F32.max(x1, vx(q)), F32.max(z1, vz(q))})

def bbox(+ps: List<&2, V>) -> Box:
  box_go(ps, Box{1000000.0, 1000000.0, F32.neg(1000000.0), F32.neg(1000000.0)})

def pad(+b: Box, +d: F32) -> Box:
  match b:
    case Box{x0, z0, x1, z1}:
      Box{(x0 - d : F32), (z0 - d : F32), (x1 + d : F32), (z1 + d : F32)}

def around(+p: V, +d: F32) -> Box:
  Box{(vx(p) - d : F32), (vz(p) - d : F32), (vx(p) + d : F32), (vz(p) + d : F32)}

def box_has(+b: Box, +p: V) -> Bool:
  match b:
    case Box{x0, z0, x1, z1}:
      Bool.and(Bool.and((vx(p) >= x0 : F32), (vx(p) <= x1 : F32)), Bool.and((vz(p) >= z0 : F32), (vz(p) <= z1 : F32)))

# The same tests on a box grown by d, without building the grown box.
def box_near(+b: Box, +p: V, +d: F32) -> Bool:
  match b:
    case Box{x0, z0, x1, z1}:
      Bool.and(Bool.and((vx(p) >= x0 - d : F32), (vx(p) <= x1 + d : F32)), Bool.and((vz(p) >= z0 - d : F32), (vz(p) <= z1 + d : F32)))

def boxes_near(+a: Box, +b: Box, +d: F32) -> Bool:
  match a:
    case Box{ax0, az0, ax1, az1}:
      match b:
        case Box{bx0, bz0, bx1, bz1}:
          Bool.and(Bool.and((ax0 - d <= bx1 : F32), (bx0 <= ax1 + d : F32)), Bool.and((az0 - d <= bz1 : F32), (bz0 <= az1 + d : F32)))

# The squared distance from p to a box: no more than to anything inside it.
def box_gap2(+b: Box, +p: V) -> F32:
  match b:
    case Box{x0, z0, x1, z1}:
      +dx = F32.max(F32.max((x0 - vx(p) : F32), (vx(p) - x1 : F32)), 0.0)
      +dz = F32.max(F32.max((z0 - vz(p) : F32), (vz(p) - z1 : F32)), 0.0)
      (dx * dx + dz * dz : F32)

def boxes_meet(+a: Box, +b: Box) -> Bool:
  match a:
    case Box{ax0, az0, ax1, az1}:
      match b:
        case Box{bx0, bz0, bx1, bz1}:
          Bool.and(Bool.and((ax0 <= bx1 : F32), (bx0 <= ax1 : F32)), Bool.and((az0 <= bz1 : F32), (bz0 <= az1 : F32)))

# ===========================================================================
# What is near: 48 m buckets over the cell, as a persistent binary tree
#
# 32 by 32 buckets from 320 m before the cell's first corner; anything past
# the edge falls in the edge bucket, so a query there only looks at more.
# An item sits in every bucket its box touches; a query reads every bucket
# its box touches and may see an item twice, which no test minds.
# ===========================================================================

type Item is Data:
  ISeg{a: V, b: V, kind: U32, sb: Box}
  ISol{what: U32, pts: List<&2, V>, box: Box}

type Tr is Data:
  Lf{xs: List<&2, Item>}
  Nd{l: Tr, r: Tr}

def tr_empty(fuel: Nat) -> Tr:
  match fuel:
    case 0n:
      Lf{Nil{}}
    case 1n+p:
      +e = tr_empty(p)
      Nd{e, e}

# A bucket's key picks the path down the tree, its highest bit first.
def tr_add(fuel: Nat, t: Tr, +k: U32, +mask: U32, +it: Item) -> Tr:
  match fuel t:
    case 0n Lf{xs}:
      Lf{it <> xs}
    case 0n Nd{l, r}:
      Nd{l, r}
    case 1n+p Lf{xs}:
      Lf{xs}
    case 1n+p Nd{+l, +r}:
      +right = U32.is_ne(U32.and(k, mask), 0)
      +new = tr_add(p, Bool.pick(Tr, right, r, l), k, U32.shrn(mask, 1n), it)
      Nd{Bool.pick(Tr, right, l, new), Bool.pick(Tr, right, new, r)}

def tr_get(fuel: Nat, +t: Tr, +k: U32, +mask: U32) -> List<&2, Item>:
  match fuel t:
    case 0n Lf{xs}:
      xs
    case 0n Nd{l, r}:
      Nil{}
    case 1n+p Lf{xs}:
      xs
    case 1n+p Nd{+l, +r}:
      tr_get(p, Bool.pick(Tr, U32.is_ne(U32.and(k, mask), 0), r, l), k, U32.shrn(mask, 1n))

def bucket(+x: F32) -> U32:
  floor_u(F32.min(((x + 320.0) / 48.0 : F32), 31.0))

def key(+bx: U32, +bz: U32) -> U32:
  U32.add(U32.mul(bz, 32), bx)

type Range is Data:
  Range{bx0: U32, bz0: U32, nx: U32, nz: U32}

def range_of(+b: Box) -> Range:
  match b:
    case Box{x0, z0, x1, z1}:
      +bx0 = bucket(x0)
      +bz0 = bucket(z0)
      Range{bx0, bz0, U32.add(U32.sub(U32.max(bucket(x1), bx0), bx0), 1), U32.add(U32.sub(U32.max(bucket(z1), bz0), bz0), 1)}

# Put an item in every bucket of a box.
def add_cols(fuel: Nat, t: Tr, +bx: U32, +bz: U32, +it: Item) -> Tr:
  match fuel:
    case 0n:
      t
    case 1n+p:
      add_cols(p, tr_add(10n, t, key(bx, bz), 512, it), U32.add(bx, 1), bz, it)

def add_rows(fuel: Nat, t: Tr, +bx0: U32, +nx: Nat, +bz: U32, +it: Item) -> Tr:
  match fuel:
    case 0n:
      t
    case 1n+p:
      add_rows(p, add_cols(nx, t, bx0, bz, it), bx0, nx, U32.add(bz, 1), it)

def put_range(r: Range, t: Tr, +it: Item) -> Tr:
  match r:
    case Range{bx0, bz0, nx, nz}:
      add_rows(U32.to_nat(nz), t, bx0, U32.to_nat(nx), bz0, it)

def tr_put(t: Tr, +b: Box, +it: Item) -> Tr:
  put_range(range_of(b), t, it)

# Everything in the buckets of a box.
def get_cols(fuel: Nat, +t: Tr, +bx: U32, +bz: U32, acc: List<&2, List<&2, Item>>) -> List<&2, List<&2, Item>>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      get_cols(p, t, U32.add(bx, 1), bz, tr_get(10n, t, key(bx, bz), 512) <> acc)

def get_rows(fuel: Nat, +t: Tr, +bx0: U32, +nx: Nat, +bz: U32, acc: List<&2, List<&2, Item>>) -> List<&2, List<&2, Item>>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      get_rows(p, t, bx0, nx, U32.add(bz, 1), get_cols(nx, t, bx0, bz, acc))

def range_near(r: Range, +t: Tr) -> List<&2, List<&2, Item>>:
  match r:
    case Range{bx0, bz0, nx, nz}:
      get_rows(U32.to_nat(nz), t, bx0, U32.to_nat(nx), bz0, Nil{})

def near(+t: Tr, +b: Box) -> List<&2, List<&2, Item>>:
  range_near(range_of(b), t)

# ===========================================================================
# Tables
# ===========================================================================

# Half the carriageway by road class; the river counts as a road 28 m wide.
def road_half(+k: U32) -> F32:
  Bool.pick(F32, U32.is_eq(k, 1), 7.0, Bool.pick(F32, U32.is_eq(k, 2), 4.5, Bool.pick(F32, U32.is_eq(k, 3), 2.0, 14.0)))

# Centreline to a lot's front, by road class.
def front(+k: U32) -> F32:
  Bool.pick(F32, U32.is_eq(k, 1), 10.0, Bool.pick(F32, U32.is_eq(k, 2), 7.0, 3.5))

# Uses: 0 rumah, 1 petak, 2 kos, 3 warung, 4 ruko, 5 minimarket, 6 bengkel,
# 7 gudang, 8 kantor, 9 apartemen, 10 rusun, 11 mal, 12 masjid, 13 gereja,
# 14 klenteng, 15 sekolah, 16 puskesmas, 17 spbu; 255 is none.
type Size is Data:
  Size{w0: F32, w1: F32, d0: F32, d1: F32, gap: F32}

def size_17(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{32.0, 40.0, 26.0, 32.0, 3.0}
    case False{}:
      Size{8.0, 11.0, 10.0, 14.0, 1.5}

def size_16(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{20.0, 26.0, 16.0, 20.0, 3.0}
    case False{}:
      size_17(U32.is_eq(u, 17), u)

def size_15(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{40.0, 50.0, 30.0, 38.0, 3.0}
    case False{}:
      size_16(U32.is_eq(u, 16), u)

def size_14(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{16.0, 20.0, 18.0, 22.0, 3.0}
    case False{}:
      size_15(U32.is_eq(u, 15), u)

def size_13(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{18.0, 24.0, 24.0, 30.0, 3.0}
    case False{}:
      size_14(U32.is_eq(u, 14), u)

def size_12(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{15.0, 20.0, 15.0, 20.0, 3.0}
    case False{}:
      size_13(U32.is_eq(u, 13), u)

def size_11(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{55.0, 70.0, 40.0, 50.0, 5.0}
    case False{}:
      size_12(U32.is_eq(u, 12), u)

def size_10(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{30.0, 40.0, 12.0, 14.0, 5.0}
    case False{}:
      size_11(U32.is_eq(u, 11), u)

def size_9(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{22.0, 26.0, 22.0, 26.0, 5.0}
    case False{}:
      size_10(U32.is_eq(u, 10), u)

def size_8(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{22.0, 28.0, 20.0, 26.0, 4.0}
    case False{}:
      size_9(U32.is_eq(u, 9), u)

def size_7(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{25.0, 35.0, 20.0, 28.0, 3.0}
    case False{}:
      size_8(U32.is_eq(u, 8), u)

def size_6(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{9.0, 12.0, 10.0, 14.0, 2.0}
    case False{}:
      size_7(U32.is_eq(u, 7), u)

def size_5(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{13.0, 16.0, 16.0, 20.0, 3.0}
    case False{}:
      size_6(U32.is_eq(u, 6), u)

def size_4(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{4.5, 6.0, 13.0, 16.0, 0.0}
    case False{}:
      size_5(U32.is_eq(u, 5), u)

def size_3(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{5.0, 7.0, 5.0, 7.0, 1.0}
    case False{}:
      size_4(U32.is_eq(u, 4), u)

def size_2(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{10.0, 13.0, 12.0, 15.0, 1.5}
    case False{}:
      size_3(U32.is_eq(u, 3), u)

def size_1(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{14.0, 18.0, 8.0, 10.0, 1.0}
    case False{}:
      size_2(U32.is_eq(u, 2), u)

def size_0(here: Bool, +u: U32) -> Size:
  match here:
    case True{}:
      Size{8.0, 11.0, 10.0, 14.0, 1.5}
    case False{}:
      size_1(U32.is_eq(u, 1), u)

def size_of(+u: U32) -> Size:
  size_0(U32.is_eq(u, 0), u)

def size_w(+s: Size, +h: F32) -> F32:
  match s:
    case Size{w0, w1, d0, d1, gap}:
      lerp(w0, w1, h)

def size_d(+s: Size, +h: F32) -> F32:
  match s:
    case Size{w0, w1, d0, d1, gap}:
      lerp(d0, d1, h)

def size_gap(+s: Size) -> F32:
  match s:
    case Size{w0, w1, d0, d1, gap}:
      gap

# A roll against thresholds: the first use whose threshold it is under.
type Cut is Data:
  Cut{at: F32, use: U32}

def pick_from(cs: List<&2, Cut>, +h: F32, +dflt: U32) -> U32:
  match cs:
    case Nil{}:
      dflt
    case Con{+c, r}:
      match c:
        case Cut{at, use}:
          Bool.pick(U32, (h < at : F32), use, pick_from(r, h, dflt))

# What a lot facing a road of class k, in a block that became `land`, at
# density d, is.
def main_use(town: Bool, +d: F32, +h: F32) -> U32:
  match town:
    case True{}:
      pick_from([Cut{0.34, 4}, Cut{0.46, 8}, Cut{0.56, 9}, Cut{0.66, 5}, Cut{0.74, 10}, Cut{0.77, 11}, Cut{0.87, 3}], h, 2)
    case False{}:
      pick_from([Cut{0.4, 4}, Cut{0.52, 3}, Cut{0.66, 0}, Cut{0.74, 5}, Cut{0.83, 6}, Cut{0.9, 2},
        Cut{Bool.pick(F32, (d < 0.32 : F32), 0.93, 0.0), 7}], h, 4)

def kampung_use(shops: Bool, +d: F32, +h: F32) -> U32:
  match shops:
    case True{}:
      pick_from([Cut{0.5, 4}, Cut{0.8, 0}], h, 3)
    case False{}:
      pick_from([Cut{0.56, 0}, Cut{0.7, 1}, Cut{(0.7 + Bool.pick(F32, (d > 0.5 : F32), 0.14, 0.05) : F32), 2}, Cut{0.89, 3}], h, 0)

def lokal_use(core: Bool, +land: U32, +d: F32, +h: F32) -> U32:
  match core:
    case True{}:
      pick_from([Cut{0.25, 2}, Cut{0.45, 4}, Cut{0.6, 8}, Cut{0.74, 9}, Cut{0.86, 10}, Cut{0.95, 5}], h, 3)
    case False{}:
      kampung_use(U32.is_eq(land, 6), d, h)

def road_use(main: Bool, +land: U32, +d: F32, +h: F32) -> U32:
  match main:
    case True{}:
      main_use((d > 0.72 : F32), d, h)
    case False{}:
      lokal_use(Bool.and(U32.is_eq(land, 4), (d > 0.72 : F32)), land, d, h)

def pick_use(+k: U32, +land: U32, +d: F32, +h: F32) -> U32:
  road_use(U32.is_ne(k, 3), land, d, h)

# A house along a road through the fields.
def ribbon_use(+h: F32) -> U32:
  pick_from([Cut{0.74, 0}, Cut{0.9, 3}], h, 1)

# A civic single, or none: an spbu only on an arterial, a klenteng only in
# town.
def civic_use(+k: U32, +d: F32, +h: F32) -> U32:
  pick_from([Cut{Bool.pick(F32, U32.is_eq(k, 1), 0.05, 0.0), 17}, Cut{0.11, 12}, Cut{0.16, 15}, Cut{0.18, 16}, Cut{0.2, 13},
    Cut{Bool.pick(F32, (d > 0.55 : F32), 0.21, 0.0), 14}], h, 255)

# ===========================================================================
# The cell, as the parcels see it
# ===========================================================================

# A block: what it became, its density, and its outline on the ground.
type Ba is Data:
  Ba{land: U32, d: F32, poly: List<&2, V>, last: V, box: Box}

# A road, measured: each straight run from a point, its direction, where
# along the road it starts, and its length.
type Run is Data:
  Run{a: V, t: V, s0: F32, l: F32}

type Rd is Data:
  Rd{kind: U32, len: F32, runs: List<&2, Run>}

type Ctx is Data:
  Ctx{key: U32, roads: Tr, blocks: List<&2, Ba>, streets: List<&2, Rd>}

# A rectangle of the frame (65536ths), n points a side, from the corner o.
def side_pts(fuel: Nat, +f: W.Frame, +o: W.Pt, +u0: U32, +v0: U32, +u1: U32, +v1: U32, +n: U32, +k: U32, acc: List<&2, V>) -> List<&2, V>:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      +t = U32.div(U32.mul(k, 65536), n)
      side_pts(p, f, o, u0, v0, u1, v1, n, U32.add(k, 1), local(o, W.frame_at(f, W.lerp(u0, u1, t), W.lerp(v0, v1, t))) <> acc)

def frame_poly(+f: W.Frame, +o: W.Pt, +u0: U32, +u1: U32, +v0: U32, +v1: U32, +n: U32) -> List<&2, V>:
  +m = U32.to_nat(n)
  List.reverse(&2, V,
    side_pts(m, f, o, u0, v1, u0, v0, n, 0,
    side_pts(m, f, o, u1, v1, u0, v1, n, 0,
    side_pts(m, f, o, u1, v0, u1, v1, n, 0,
    side_pts(m, f, o, u0, v0, u1, v0, n, 0, Nil{})))))

def fill_land(+x: W.Fill) -> U32:
  match x:
    case W.Fill{land, court, ring, streets, mouths, linked, bulb, thru}:
      land

def block_area(+f: W.Frame, +o: W.Pt, +b: W.Blk) -> Ba:
  match b:
    case W.Blk{u0, u1, v0, v1, d, sr, nr, wr, er, fill}:
      +poly = frame_poly(f, o, u0, u1, v0, v1, 12)
      Ba{fill_land(fill), (f32(d) / 1024.0 : F32), poly, last_v(poly, V{0.0, 0.0}), bbox(poly)}

def areas(bs: List<&2, W.Blk>, +f: W.Frame, +o: W.Pt) -> List<&2, Ba>:
  match bs:
    case Nil{}:
      Nil{}
    case Con{+b, r}:
      block_area(f, o, b) <> areas(r, f, o)

def to_local(ps: List<&2, W.Pt>, +o: W.Pt) -> List<&2, V>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+p, r}:
      local(o, p) <> to_local(r, o)

# Every piece of a road into the index, its box padded by the carriageway
# and 12 m more.
def put_pieces(ps: List<&2, V>, +prev: V, +kind: U32, t: Tr) -> Tr:
  match ps:
    case Nil{}:
      t
    case Con{+q, r}:
      put_pieces(r, q, kind, tr_put(t, pad(bbox([prev, q]), (road_half(kind) + 12.0 : F32)), ISeg{prev, q, kind, bbox([prev, q])}))

def put_road(+pts: List<&2, V>, +kind: U32, t: Tr) -> Tr:
  match pts:
    case Nil{}:
      t
    case Con{+q, r}:
      put_pieces(r, q, kind, t)

def run_go(ps: List<&2, V>, +prev: V, +s: F32, acc: List<&2, Run>) -> Rd:
  match ps:
    case Nil{}:
      Rd{0, s, List.reverse(&2, Run, acc)}
    case Con{+q, r}:
      +dx = (vx(q) - vx(prev) : F32)
      +dz = (vz(q) - vz(prev) : F32)
      +l = hypot(dx, dz)
      +m = F32.max(l, 0.000001)
      run_go(r, q, (s + l : F32), Run{prev, V{(dx / m : F32), (dz / m : F32)}, s, l} <> acc)

def rd_kind(+r: Rd, +k: U32) -> Rd:
  match r:
    case Rd{kind, len, runs}:
      Rd{k, len, runs}

def measure(+pts: List<&2, V>, +kind: U32) -> Rd:
  match pts:
    case Nil{}:
      Rd{kind, 0.0, Nil{}}
    case Con{+q, r}:
      rd_kind(run_go(r, q, 0.0, Nil{}), kind)

# A road's lines as (class, points): the river is class 0.
type Way is Data:
  Way{kind: U32, pts: List<&2, V>}

def ways(ls: List<&2, W.Line>, +o: W.Pt) -> List<&2, Way>:
  match ls:
    case Nil{}:
      Nil{}
    case Con{+l, r}:
      match l:
        case W.Line{kind, tag, pts}:
          Way{Bool.pick(U32, U32.is_eq(tag, 3), 0, kind), to_local(pts, o)} <> ways(r, o)

# The cell's north and east lattice roads belong to its neighbours, but bound
# its lots too.
def far_road(here: Bool, +seed: U32, +i: U32, +j: U32, +east: Bool, +o: W.Pt) -> List<&2, Way>:
  match here:
    case False{}:
      Nil{}
    case True{}:
      [Way{W.road_code(i, j, east), to_local(W.road_pts(seed, i, j, east), o)}]

def index_ways(ws: List<&2, Way>, t: Tr) -> Tr:
  match ws:
    case Nil{}:
      t
    case Con{+w, r}:
      match w:
        case Way{kind, pts}:
          index_ways(r, put_road(pts, kind, t))

def streets_of(ws: List<&2, Way>, +k: U32) -> List<&2, Rd>:
  match ws:
    case Nil{}:
      Nil{}
    case Con{+w, r}:
      match w:
        case Way{kind, pts}:
          +rest = streets_of(r, k)
          Bool.pick(List<&2, Rd>, U32.is_eq(kind, k), measure(pts, kind) <> rest, rest)

# ===========================================================================
# Placing
# ===========================================================================

# A lot's use and outline; its first edge faces its street.
type Lot is Data:
  Lot{use: U32, pts: List<&2, V>}

# A court: 0 alun, 1 pasar, 2 sekolah, 3 gudang, 4 lapangan, 5 masjid, 6
# pendopo. A yard is only ground: the courts inside it hold the buildings.
type Court is Data:
  Court{use: U32, yard: Bool, pts: List<&2, V>}

# A canopy: 0 mangga, 1 beringin, 2 flamboyan, 3 bambu.
type Tree is Data:
  Tree{x: F32, z: F32, r: F32, sp: U32}

# What stands so far, and the index of what a new lot may not touch: lots
# (0), courts (1) and the yard of an alun-alun (2), which trees may grow in.
type St is Data:
  St{sol: Tr, lots: List<&2, Lot>, courts: List<&2, Court>, trees: List<&2, Tree>}

type Hit is Data:
  Hit{found: Bool, land: U32, d: F32}

def in_block(near: Bool, +b: Ba, +p: V) -> Bool:
  match near:
    case False{}:
      False{}
    case True{}:
      match b:
        case Ba{land, d, poly, last, box}:
          in_go(poly, p, last, False{})

def block_at(bs: List<&2, Ba>, +p: V, +miss: Hit) -> Hit:
  match bs:
    case Nil{}:
      miss
    case Con{+b, r}:
      match b:
        case Ba{land, d, poly, last, box}:
          block_at(r, p, Bool.pick(Hit, in_block(box_has(box, p), Ba{land, d, poly, last, box}, p), Hit{True{}, land, d}, miss))

def hit_found(+h: Hit) -> Bool:
  match h:
    case Hit{found, land, d}:
      found

def all_in(ps: List<&2, V>, +bs: List<&2, Ba>) -> Bool:
  match ps:
    case Nil{}:
      True{}
    case Con{+q, r}:
      Bool.and(hit_found(block_at(bs, q, Hit{False{}, 0, 0.0})), all_in(r, bs))

# Whether a lot keeps its front verge beyond every road's front line, and
# 6 m from the river.
# A piece whose box, grown by what the lot needs and a metre more, misses the
# lot's box is further than that from the lot, so only the rest are measured.
def piece_blocks(close: Bool, +poly: List<&2, V>, +a: V, +b: V, +need: F32) -> Bool:
  match close:
    case False{}:
      False{}
    case True{}:
      (poly_seg(poly, a, b) < need : F32)

def blocked_in(xs: List<&2, Item>, +poly: List<&2, V>, +pb: Box) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+it, r}:
      match it:
        case ISeg{a, b, kind, sb}:
          +need = Bool.pick(F32, U32.is_eq(kind, 0), 20.0, (front(kind) - 0.6 : F32))
          Bool.or(piece_blocks(boxes_near(sb, pb, (need + 1.0 : F32)), poly, a, b, need), blocked_in(r, poly, pb))
        case ISol{what, pts, box}:
          blocked_in(r, poly, pb)

def blocked(bs: List<&2, List<&2, Item>>, +poly: List<&2, V>) -> Bool:
  match bs:
    case Nil{}:
      False{}
    case Con{+xs, r}:
      Bool.or(blocked_in(xs, poly, bbox(poly)), blocked(r, poly))

# Two solids whose boxes stand a metre apart cannot come within the 0.3 m the
# overlap test allows: a rectangle's edge normals see at least 0.7 of a gap.
def solid_touches(close: Bool, +pts: List<&2, V>, +poly: List<&2, V>) -> Bool:
  match close:
    case False{}:
      False{}
    case True{}:
      overlap(pts, poly)

def touching_in(xs: List<&2, Item>, +poly: List<&2, V>, +pb: Box) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+it, r}:
      match it:
        case ISeg{a, b, kind, sb}:
          touching_in(r, poly, pb)
        case ISol{what, pts, box}:
          Bool.or(solid_touches(boxes_near(box, pb, 1.0), pts, poly), touching_in(r, poly, pb))

def touching(bs: List<&2, List<&2, Item>>, +poly: List<&2, V>) -> Bool:
  match bs:
    case Nil{}:
      False{}
    case Con{+xs, r}:
      Bool.or(touching_in(xs, poly, bbox(poly)), touching(r, poly))

def ctx_roads(+c: Ctx) -> Tr:
  match c:
    case Ctx{key, roads, blocks, streets}:
      roads

def ctx_blocks(+c: Ctx) -> List<&2, Ba>:
  match c:
    case Ctx{key, roads, blocks, streets}:
      blocks

def ctx_key(+c: Ctx) -> U32:
  match c:
    case Ctx{key, roads, blocks, streets}:
      key

def st_sol(+s: St) -> Tr:
  match s:
    case St{sol, lots, courts, trees}:
      sol

def add_lot(+s: St, +use: U32, +poly: List<&2, V>) -> St:
  match s:
    case St{sol, lots, courts, trees}:
      +box = bbox(poly)
      St{tr_put(sol, box, ISol{0, poly, box}), Lot{use, poly} <> lots, courts, trees}

def add_court(+s: St, +c: Court) -> St:
  match s:
    case St{sol, lots, courts, trees}:
      match c:
        case Court{use, yard, pts}:
          +box = bbox(pts)
          St{tr_put(sol, box, ISol{Bool.pick(U32, U32.is_eq(use, 0), 2, 1), pts, box}), lots, Court{use, yard, pts} <> courts, trees}

def add_tree(+s: St, +t: Tree) -> St:
  match s:
    case St{sol, lots, courts, trees}:
      St{sol, lots, courts, t <> trees}

type Put is Data:
  Put{st: St, ok: Bool}

def put_if(ok: Bool, +s: St, +use: U32, +poly: List<&2, V>) -> Put:
  match ok:
    case True{}:
      Put{add_lot(s, use, poly), True{}}
    case False{}:
      Put{s, False{}}

def put_free(clear: Bool, +s: St, +use: U32, +poly: List<&2, V>) -> Put:
  match clear:
    case True{}:
      put_if(Bool.not(touching(near(st_sol(s), bbox(poly)), poly)), s, use, poly)
    case False{}:
      Put{s, False{}}

def put_in(inside: Bool, +c: Ctx, +s: St, +use: U32, +poly: List<&2, V>) -> Put:
  match inside:
    case True{}:
      put_free(Bool.not(blocked(near(ctx_roads(c), bbox(poly)), poly)), s, use, poly)
    case False{}:
      Put{s, False{}}

# A lot stands if it lies inside the cell's blocks, keeps clear of the roads,
# and touches nothing placed before it.
def place(+c: Ctx, +s: St, +use: U32, +poly: List<&2, V>) -> Put:
  put_in(all_in(poly, ctx_blocks(c)), c, s, use, poly)

# ===========================================================================
# Civic courts inside ring blocks
#
# A court is town-sized, not block-sized: it sits against the ring lane, and
# the rest of the inside is kampung. An alun-alun is a field with the masjid
# on its west, a pendopo north and beringin at its corners; a sekolah is a
# school beside its own field. Sizes are centimetres in the block's metric
# frame.
# ===========================================================================

# How big a court may grow inside its ring, the long side and the short one.
def court_long(+c: U32) -> U32:
  Bool.pick(U32, U32.is_eq(c, 0), 12000, Bool.pick(U32, U32.is_eq(c, 1), 8000, 9000))

def court_short(+c: U32) -> U32:
  Bool.pick(U32, U32.is_eq(c, 0), 9500, Bool.pick(U32, U32.is_eq(c, 1), 6000, Bool.pick(U32, U32.is_eq(c, 2), 6000, 6500)))

type Rect is Data:
  Rect{u0: U32, u1: U32, v0: U32, v1: U32}

# A rectangle of the metric frame as a court's outline, 8 points a side.
def court_of(+f: W.Frame, +o: W.Pt, +use: U32, +yard: Bool, +r: Rect) -> Court:
  match r:
    case Rect{u0, u1, v0, v1}:
      +mu = W.frame_mu(f)
      +mv = W.frame_mv(f)
      Court{use, yard, frame_poly(f, o, W.frac16(u0, mu), W.frac16(u1, mu), W.frac16(v0, mv), W.frac16(v1, mv), 8)}

def tree_at(+f: W.Frame, +o: W.Pt, +x: U32, +z: U32, +r: F32, +sp: U32) -> Tree:
  +p = local(o, W.frame_at(f, W.frac16(x, W.frame_mu(f)), W.frac16(z, W.frame_mv(f))))
  Tree{vx(p), vz(p), r, sp}

# Trim one side of a span to `most`, from the low end or the high one.
def trim_lo(+a: U32, +b: U32, +most: U32, +keep_lo: Bool) -> U32:
  Bool.pick(U32, Bool.and(U32.is_gt(U32.sub(b, a), most), Bool.not(keep_lo)), U32.sub(b, most), a)

def trim_hi(+a: U32, +b: U32, +most: U32, +keep_lo: Bool) -> U32:
  Bool.pick(U32, Bool.and(U32.is_gt(U32.sub(b, a), most), keep_lo), U32.add(a, most), b)

def alun(+f: W.Frame, +o: W.Pt, +r: Rect, s: St) -> St:
  match r:
    case Rect{+u0, +u1, +v0, +v1}:
      +fu0 = U32.add(u0, 3400)
      +fu1 = U32.sub(u1, 1600)
      +fv0 = U32.add(v0, 1600)
      +fv1 = U32.sub(v1, 2000)
      +mid = U32.shrn(U32.add(v0, v1), 1n)
      +half = U32.min(1400, U32.sub(U32.shrn(U32.sub(v1, v0), 1n), 400))
      +cu = U32.shrn(U32.add(fu0, fu1), 1n)
      +ph = U32.min(1000, U32.shrn(U32.sub(u1, u0), 2n))
      +s1 = add_court(add_court(add_court(s,
        court_of(f, o, 4, False{}, Rect{fu0, fu1, fv0, fv1})),
        court_of(f, o, 5, False{}, Rect{U32.add(u0, 300), U32.add(u0, 3000), U32.sub(mid, half), U32.add(mid, half)})),
        court_of(f, o, 6, False{}, Rect{U32.sub(cu, ph), U32.add(cu, ph), U32.add(fv1, 300), U32.sub(v1, 200)}))
      add_tree(add_tree(add_tree(add_tree(s1,
        tree_at(f, o, fu0, fv0, 7.5, 1)), tree_at(f, o, fu1, fv0, 7.5, 1)),
        tree_at(f, o, fu0, fv1, 7.5, 1)), tree_at(f, o, fu1, fv1, 7.5, 1))

def sekolah(+f: W.Frame, +o: W.Pt, +r: Rect, s: St) -> St:
  match r:
    case Rect{+u0, +u1, +v0, +v1}:
      +along_u = U32.is_ge(U32.sub(u1, u0), U32.sub(v1, v0))
      +su = U32.add(u0, U32.div(U32.mul(U32.sub(u1, u0), 55), 100))
      +sv = U32.add(v0, U32.div(U32.mul(U32.sub(v1, v0), 55), 100))
      add_court(add_court(s,
        court_of(f, o, 2, False{}, Bool.pick(Rect, along_u, Rect{u0, su, v0, v1}, Rect{u0, u1, v0, sv}))),
        court_of(f, o, 4, False{}, Bool.pick(Rect, along_u, Rect{U32.add(su, 400), u1, v0, v1}, Rect{u0, u1, U32.add(sv, 400), v1})))

def school_or(is_school: Bool, +f: W.Frame, +o: W.Pt, +r: Rect, +s: St) -> St:
  match is_school:
    case True{}:
      sekolah(f, o, r, s)
    case False{}:
      s

def alun_or(is_alun: Bool, +c: U32, +f: W.Frame, +o: W.Pt, +r: Rect, +s: St) -> St:
  match is_alun:
    case True{}:
      alun(f, o, r, s)
    case False{}:
      school_or(U32.is_eq(c, 2), f, o, r, s)

def inside_court(+c: U32, +f: W.Frame, +o: W.Pt, +r: Rect, +s: St) -> St:
  alun_or(U32.is_eq(c, 0), c, f, o, r, s)

def court_go(go: Bool, +key: U32, +f: W.Frame, +o: W.Pt, +c: U32, +ring: W.Box, +u0: U32, +v0: U32, s: St) -> St:
  match go:
    case False{}:
      s
    case True{}:
      match ring:
        case W.Box{x0, x1, z0, z1}:
          # Inside the ring lane's verge.
          +a0 = U32.add(x0, 350)
          +a1 = U32.sub(x1, 350)
          +b0 = U32.add(z0, 350)
          +b1 = U32.sub(z1, 350)
          +long_u = U32.is_ge(U32.sub(a1, a0), U32.sub(b1, b0))
          +cl = Bool.pick(U32, long_u, court_long(c), court_short(c))
          +cs = Bool.pick(U32, long_u, court_short(c), court_long(c))
          +hu = (r2(key, 60, u0) < 0.5 : F32)
          +hv = (r2(key, 61, v0) < 0.5 : F32)
          +r = {Rect{trim_lo(a0, a1, cl, hu), trim_hi(a0, a1, cl, hu), trim_lo(b0, b1, cs, hv), trim_hi(b0, b1, cs, hv)} : Rect}
          +yard = Bool.or(U32.is_eq(c, 0), U32.is_eq(c, 2))
          inside_court(c, f, o, r, add_court(s, court_of(f, o, c, yard, r)))

def blk_courts(bs: List<&2, W.Blk>, +key: U32, +f: W.Frame, +o: W.Pt, s: St) -> St:
  match bs:
    case Nil{}:
      s
    case Con{+b, r}:
      match b:
        case W.Blk{u0, u1, v0, v1, d, sr, nr, wr, er, fill}:
          match fill:
            case W.Fill{land, court, ring, streets, mouths, linked, bulb, thru}:
              blk_courts(r, key, f, o, court_go(U32.is_lt(court, 4), key, f, o, court, ring, u0, v0, s))

# ===========================================================================
# Lots along every road
# ===========================================================================

type At is Data:
  At{p: V, t: V}

def run_at(+r: Run, +s: F32) -> At:
  match r:
    case Run{a, t, s0, l}:
      At{V{(vx(a) + vx(t) * (s - s0) : F32), (vz(a) + vz(t) * (s - s0) : F32)}, t}

def run_end(+r: Run) -> F32:
  match r:
    case Run{a, t, s0, l}:
      (s0 + l : F32)

def at_go(rs: List<&2, Run>, +s: F32, +best: Run) -> At:
  match rs:
    case Nil{}:
      run_at(best, s)
    case Con{+r, rest}:
      Bool.pick(At, (s <= run_end(r) : F32), run_at(r, s), at_go(rest, s, r))

# The point a distance s along a road, and the road's direction there.
def rd_at(+rd: Rd, +s: F32) -> At:
  match rd:
    case Rd{kind, len, runs}:
      match runs:
        case Nil{}:
          At{V{0.0, 0.0}, V{1.0, 0.0}}
        case Con{+r0, rest}:
          at_go(rest, s, r0) 

def rd_len(+rd: Rd) -> F32:
  match rd:
    case Rd{kind, len, runs}:
      len

def rd_kindof(+rd: Rd) -> U32:
  match rd:
    case Rd{kind, len, runs}:
      kind

def at_p(+a: At) -> V:
  match a:
    case At{p, t}:
      p

def at_t(+a: At) -> V:
  match a:
    case At{p, t}:
      t

# A point off the road: `along` further on, `out` to the side (side is 1 or
# -1, to the right or left of travel).
def off(+a: At, +along: F32, +out: F32) -> V:
  +p = at_p(a)
  +t = at_t(a)
  V{(vx(p) + vx(t) * along - vz(t) * out : F32), (vz(p) + vz(t) * along + vx(t) * out : F32)}

# The block beside a point of a road.
def beside(+c: Ctx, +rd: Rd, +s: F32, +side: F32) -> Hit:
  block_at(ctx_blocks(c), off(rd_at(rd, F32.min(s, rd_len(rd))), 0.0, ((front(rd_kindof(rd)) + 6.0) * side : F32)), Hit{False{}, 0, 0.0})

type Got is Data:
  Got{st: St, w: F32}

def got_of(+p: Put, +w: F32) -> Got:
  match p:
    case Put{st, ok}:
      Got{st, Bool.pick(F32, ok, w, 0.0)}

def lot_go(fits: Bool, +c: Ctx, +s: St, +rd: Rd, +at: F32, +side: F32, +use: U32, +w: F32, +dep: F32) -> Got:
  match fits:
    case False{}:
      Got{s, 0.0}
    case True{}:
      +a = rd_at(rd, (at + w / 2.0 : F32))
      +f = (front(rd_kindof(rd)) + 0.3 : F32)
      +hw = (w / 2.0 : F32)
      +poly = {[off(a, F32.neg(hw), (f * side : F32)), off(a, hw, (f * side : F32)),
               off(a, hw, ((f + dep) * side : F32)), off(a, F32.neg(hw), ((f + dep) * side : F32))] : List<&2, V>}
      got_of(place(c, s, use, poly), w)

# A lot of `use` facing the road at `at`, its frontage and depth rolled from
# h and h2; its width, or 0 where it does not stand.
def lot_at(+c: Ctx, +s: St, +rd: Rd, +at: F32, +side: F32, +use: U32, +h: F32, +h2: F32) -> Got:
  +sz = size_of(use)
  +w = size_w(sz, h)
  lot_go((at + w <= rd_len(rd) - 2.0 : F32), c, s, rd, at, side, use, w, size_d(sz, h2))

def got_st(+g: Got) -> St:
  match g:
    case Got{st, w}:
      st

def got_w(+g: Got) -> F32:
  match g:
    case Got{st, w}:
      w

def side_code(+side: F32) -> U32:
  Bool.pick(U32, (side > 0.0 : F32), 1, 0)

# ---- Civic singles: one roll per 100 m of road side --------------------------

def civic_lot(none: Bool, +use: U32, +c: Ctx, +s: St, +rd: Rd, +n: U32, +side: F32, +k: U32, +s0: F32) -> St:
  match none:
    case True{}:
      s
    case False{}:
      +key = ctx_key(c)
      +sc = side_code(side)
      got_st(lot_at(c, s, rd, (s0 + 10.0 + r4(key, n, sc, k, 43) * 40.0 : F32), side, use, r4(key, n, sc, k, 44), r4(key, n, sc, k, 45)))

def civic_place(+use: U32, +c: Ctx, +s: St, +rd: Rd, +n: U32, +side: F32, +k: U32, +s0: F32) -> St:
  civic_lot(U32.is_eq(use, 255), use, c, s, rd, n, side, k, s0)

def civic_hit(+h: Hit, +c: Ctx, +s: St, +rd: Rd, +n: U32, +side: F32, +k: U32, +s0: F32) -> St:
  match h:
    case Hit{found, land, d}:
      +roll = r4(ctx_key(c), n, side_code(side), k, 42)
      +open = U32.is_lt(land, 2)
      civic_place(Bool.pick(U32, found, civic_use(rd_kindof(rd), d, Bool.pick(F32, open, (roll * 2.5 : F32), roll)), 255), c, s, rd, n, side, k, s0)

def civic_go(go: Bool, +c: Ctx, +s: St, +rd: Rd, +n: U32, +side: F32, +k: U32, +s0: F32) -> St:
  match go:
    case False{}:
      s
    case True{}:
      civic_hit(beside(c, rd, (s0 + 30.0 : F32), side), c, s, rd, n, side, k, s0)

def civic_walk(fuel: Nat, +c: Ctx, s: St, +rd: Rd, +n: U32, +side: F32, +k: U32) -> St:
  match fuel:
    case 0n:
      s
    case 1n+p:
      +s0 = (f32(k) * 100.0 : F32)
      civic_walk(p, c, civic_go((s0 < rd_len(rd) - 40.0 : F32), c, s, rd, n, side, k, s0), rd, n, side, U32.add(k, 1))

def civic_street(+c: Ctx, +s: St, +rd: Rd, +n: U32) -> St:
  +fuel = U32.to_nat(U32.add(floor_u((rd_len(rd) / 100.0 : F32)), 1))
  civic_walk(fuel, c, civic_walk(fuel, c, s, rd, n, 1.0, 0), rd, n, F32.neg(1.0), 0)

# ---- Every road side, walked lot by lot ----------------------------------------

type Walk is Data:
  Walk{st: St, s: F32, run: U32, step: U32}

# The third try, a warung, a quarter of the time.
def try3(go: Bool, +c: Ctx, +g: Got, +rd: Rd, +at: F32, +side: F32, +rk: U32) -> Got:
  match go:
    case False{}:
      g
    case True{}:
      lot_at(c, got_st(g), rd, at, side, 3, r2(rk, 5, 0), r2(rk, 10, 0))

def after2(+g: Got, +c: Ctx, +rd: Rd, +at: F32, +side: F32, +rk: U32) -> Got:
  try3(Bool.and((got_w(g) <= 0.0 : F32), (r2(rk, 7, 0) < 0.25 : F32)), c, g, rd, at, side, rk)

# The second try, a rumah, where the first was not one already.
def try2(go: Bool, +c: Ctx, +g: Got, +rd: Rd, +at: F32, +side: F32, +rk: U32) -> Got:
  match go:
    case False{}:
      g
    case True{}:
      lot_at(c, got_st(g), rd, at, side, 0, r2(rk, 4, 0), r2(rk, 9, 0))

def after1(+g: Got, +c: Ctx, +rd: Rd, +at: F32, +side: F32, +use: U32, +rk: U32) -> Got:
  +again = Bool.and((got_w(g) <= 0.0 : F32), Bool.and(U32.is_ne(use, 0), U32.is_ne(use, 3)))
  after2(try2(again, c, g, rd, at, side, rk), c, rd, at, side, rk)

def advance(+g: Got, +s: F32, +run: U32, +step: U32, +use: U32, +sawah: Bool, +rk: U32) -> Walk:
  match g:
    case Got{st, w}:
      +gap = Bool.pick(F32, U32.is_gt(run, 1), 0.0, (size_gap(size_of(use)) + r2(rk, 6, 0) * Bool.pick(F32, sawah, 6.0, 1.5) : F32))
      Bool.pick(Walk, (w > 0.0 : F32),
        Walk{st, (s + w + gap : F32), Bool.pick(U32, U32.is_gt(run, 0), U32.sub(run, 1), 0), step},
        Walk{st, (s + 3.0 : F32), 0, step})

def lay(+c: Ctx, +rd: Rd, +side: F32, +s: St, +at: F32, +run: U32, +step: U32, +use: U32, +sawah: Bool, +rk: U32) -> Walk:
  +run1 = Bool.pick(U32, Bool.and(U32.is_eq(use, 4), U32.is_eq(run, 0)), U32.add(3, floor_u((r2(rk, 2, 0) * 7.0 : F32))), run)
  +g = after1(lot_at(c, s, rd, at, side, use, r2(rk, 3, 0), r2(rk, 8, 0)), c, rd, at, side, use, rk)
  advance(g, at, run1, step, use, sawah, rk)

# Along a road through sawah or kebun, a ribbon of houses 160 m at a time.
def walk_field(skip: Bool, +c: Ctx, +rd: Rd, +side: F32, +s: St, +at: F32, +run: U32, +step: U32, +land: U32, +h: F32, +rk: U32) -> Walk:
  match skip:
    case True{}:
      Walk{s, (at + 6.0 : F32), run, step}
    case False{}:
      lay(c, rd, side, s, at, run, step, ribbon_use(h), U32.is_eq(land, 0), rk)

def walk_kampung(open: Bool, +skip: Bool, +c: Ctx, +rd: Rd, +side: F32, +s: St, +at: F32, +run: U32, +step: U32, +land: U32, +d: F32, +h: F32, +rk: U32) -> Walk:
  match open:
    case True{}:
      walk_field(skip, c, rd, side, s, at, run, step, land, h, rk)
    case False{}:
      lay(c, rd, side, s, at, run, step, Bool.pick(U32, U32.is_gt(run, 0), 4, pick_use(rd_kindof(rd), land, d, h)), False{}, rk)

def walk_found(found: Bool, +open: Bool, +skip: Bool, +c: Ctx, +rd: Rd, +side: F32, +s: St, +at: F32, +run: U32, +step: U32, +land: U32, +d: F32, +h: F32, +rk: U32) -> Walk:
  match found:
    case False{}:
      Walk{s, (at + 4.0 : F32), run, step}
    case True{}:
      walk_kampung(open, skip, c, rd, side, s, at, run, step, land, d, h, rk)

def walk_hit(+hit: Hit, +c: Ctx, +rd: Rd, +n: U32, +side: F32, +s: St, +at: F32, +run: U32, +step: U32) -> Walk:
  match hit:
    case Hit{found, land, d}:
      +rk = W.mix(W.mix(W.mix(ctx_key(c), n), side_code(side)), step)
      +h = r2(rk, 1, 0)
      +stretch = r4(ctx_key(c), n, side_code(side), 900, floor_u((at / 160.0 : F32)))
      walk_found(found, U32.is_lt(land, 2), (stretch > Bool.pick(F32, U32.is_eq(land, 1), 0.65, 0.5) : F32),
        c, rd, side, s, at, run, step, land, d, h, rk)

def walk_go(go: Bool, +c: Ctx, +rd: Rd, +n: U32, +side: F32, +w: Walk) -> Walk:
  match go:
    case False{}:
      w
    case True{}:
      match w:
        case Walk{st, at, run, step}:
          walk_hit(beside(c, rd, (at + 4.0 : F32), side), c, rd, n, side, st, at, run, U32.add(step, 1))

def walk_s(+w: Walk) -> F32:
  match w:
    case Walk{st, s, run, step}:
      s

def walk(fuel: Nat, +c: Ctx, +rd: Rd, +n: U32, +side: F32, +w: Walk) -> Walk:
  match fuel:
    case 0n:
      w
    case 1n+p:
      walk(p, c, rd, n, side, walk_go((walk_s(w) < rd_len(rd) - 4.0 : F32), c, rd, n, side, w))

def walk_st(+w: Walk) -> St:
  match w:
    case Walk{st, s, run, step}:
      st

def walk_side(+c: Ctx, +s: St, +rd: Rd, +n: U32, +side: F32) -> St:
  +fuel = U32.to_nat(U32.add(floor_u((rd_len(rd) / 3.0 : F32)), 2))
  walk_st(walk(fuel, c, rd, n, side, Walk{s, (2.0 + r3(ctx_key(c), n, side_code(side), 1) * 5.0 : F32), 0, 0}))

def frontage(rs: List<&2, Rd>, +c: Ctx, +n: U32, s: St) -> St:
  match rs:
    case Nil{}:
      s
    case Con{+rd, r}:
      frontage(r, c, U32.add(n, 1), walk_side(c, walk_side(c, s, rd, n, 1.0), rd, n, F32.neg(1.0)))

def civics(rs: List<&2, Rd>, +c: Ctx, +n: U32, s: St) -> St:
  match rs:
    case Nil{}:
      s
    case Con{+rd, r}:
      civics(r, c, U32.add(n, 1), civic_street(c, s, rd, n))

# ===========================================================================
# Back lots
#
# Kampung land behind the frontage fills with houses reached by gangs, which
# the road layer does not draw, on a jittered lattice; each faces the
# nearest street. A town-core grid holds apartemen, rusun and kantor.
# ===========================================================================

type Nb is Data:
  Nb{found: Bool, a: V, b: V, d: F32}

def nb_d(+nb: Nb) -> F32:
  match nb:
    case Nb{found, a, b, d}:
      d

# Nearer, or as near and first by its ends, so that which piece wins does
# not depend on the order the buckets are read in.
def v_before(+p: V, +q: V) -> Bool:
  Bool.or((vx(p) < vx(q) : F32), Bool.and(F32.is_eq(vx(p), vx(q)), (vz(p) < vz(q) : F32)))

def v_same(+p: V, +q: V) -> Bool:
  Bool.and(F32.is_eq(vx(p), vx(q)), F32.is_eq(vz(p), vz(q)))

def before(+d: F32, +a: V, +b: V, +best: Nb) -> Bool:
  match best:
    case Nb{found, ba, bb, bd}:
      Bool.or((d < bd : F32), Bool.and(F32.is_eq(d, bd), Bool.or(v_before(a, ba), Bool.and(v_same(a, ba), v_before(b, bb)))))

# A street piece, measured only when its box could hold a nearer point.
def nearer(look: Bool, +p: V, +a: V, +b: V, +best: Nb) -> Nb:
  match look:
    case False{}:
      best
    case True{}:
      +d = point_seg2(p, a, b)
      Bool.pick(Nb, before(d, a, b, best), Nb{True{}, a, b, d}, best)

def nearest_in(xs: List<&2, Item>, +p: V, +best: Nb) -> Nb:
  match xs:
    case Nil{}:
      best
    case Con{+it, r}:
      match it:
        case ISol{what, pts, box}:
          nearest_in(r, p, best)
        case ISeg{a, b, kind, sb}:
          nearest_in(r, p, nearer(Bool.and(U32.is_ne(kind, 0), (box_gap2(sb, p) <= nb_d(best) * 1.001 + 0.01 : F32)), p, a, b, best))

def nearest_street(bs: List<&2, List<&2, Item>>, +p: V, +best: Nb) -> Nb:
  match bs:
    case Nil{}:
      best
    case Con{+xs, r}:
      nearest_street(r, p, nearest_in(xs, p, best))

type Lat is Data:
  Lat{x0: U32, z0: U32, nx: U32, nz: U32}

# The lattice cells over a box, from 1 km before the cell's corner.
def lattice(+b: Box, +step: F32) -> Lat:
  match b:
    case Box{x0, z0, x1, z1}:
      +a = floor_u(((x0 + 1000.0) / step : F32))
      +c = floor_u(((z0 + 1000.0) / step : F32))
      Lat{a, c, U32.add(U32.sub(floor_u(((x1 + 1000.0) / step : F32)), a), 1), U32.add(U32.sub(floor_u(((z1 + 1000.0) / step : F32)), c), 1)}

def at_lattice(+k: U32, +step: F32) -> F32:
  (f32(k) * step - 1000.0 : F32)

def back_use(core: Bool, +d: F32, +h2: F32) -> U32:
  match core:
    case True{}:
      pick_from([Cut{0.4, 9}, Cut{0.7, 10}], h2, 8)
    case False{}:
      pick_from([Cut{0.68, 0}, Cut{0.82, 1}, Cut{Bool.pick(F32, (d > 0.5 : F32), 2.0, 0.9), 2}], h2, 0)

def back_place(found: Bool, +c: Ctx, +s: St, +use: U32, +poly: List<&2, V>) -> St:
  match found:
    case False{}:
      s
    case True{}:
      got_st(got_of(place(c, s, use, poly), 0.0))

def back_face(+nb: Nb, +c: Ctx, +s: St, +p: V, +core: Bool, +d: F32, +h: F32, +h2: F32) -> St:
  match nb:
    case Nb{found, a, b, nd}:
      +l = F32.max(dist(a, b), 0.000001)
      +tx = ((vx(b) - vx(a)) / l : F32)
      +tz = ((vz(b) - vz(a)) / l : F32)
      +use = back_use(core, d, h2)
      +sz = size_of(use)
      +k = Bool.pick(F32, core, 1.0, 0.85)
      +hw = (size_w(sz, (h * 0.8 : F32)) * k / 2.0 : F32)
      +hd = (size_d(sz, h2) * k / 2.0 : F32)
      +q = {At{p, V{tx, tz}} : At}
      back_place(found, c, s, use, [off(q, F32.neg(hw), F32.neg(hd)), off(q, hw, F32.neg(hd)), off(q, hw, hd), off(q, F32.neg(hw), hd)])

def nb_found(+nb: Nb) -> Bool:
  match nb:
    case Nb{found, a, b, d}:
      found

# The nearest street within 70 m. Every piece within r of p is in the buckets
# of the box p ± r, so a street found within 30 m needs no wider look.
def nearest_wide(found: Bool, +c: Ctx, +p: V, +nb: Nb) -> Nb:
  match found:
    case True{}:
      nb
    case False{}:
      nearest_street(near(ctx_roads(c), around(p, 70.0)), p, Nb{False{}, p, p, 4900.0})

def back_in(inside: Bool, +c: Ctx, +s: St, +p: V, +core: Bool, +d: F32, +h: F32, +h2: F32) -> St:
  match inside:
    case False{}:
      s
    case True{}:
      +nb = nearest_street(near(ctx_roads(c), around(p, 30.0)), p, Nb{False{}, p, p, 900.0})
      back_face(nearest_wide(nb_found(nb), c, p, nb), c, s, p, core, d, h, h2)

def back_try(go: Bool, +c: Ctx, +s: St, +poly: List<&2, V>, +x: F32, +z: F32, +kx: U32, +kz: U32, +core: Bool, +d: F32, +h: F32) -> St:
  match go:
    case False{}:
      s
    case True{}:
      +key = ctx_key(c)
      +p = {V{(x + (r3(key, 71, kx, kz) - 0.5) * 3.0 : F32), (z + (r3(key, 72, kx, kz) - 0.5) * 3.0 : F32)} : V}
      back_in(in_poly(p, poly), c, s, p, core, d, h, r3(key, 73, kx, kz))

def back_cols(fuel: Nat, +c: Ctx, s: St, +poly: List<&2, V>, +kx: U32, +kz: U32, +step: F32, +keep: F32, +core: Bool, +d: F32) -> St:
  match fuel:
    case 0n:
      s
    case 1n+p:
      +h = r3(ctx_key(c), 70, kx, kz)
      back_cols(p, c, back_try((h < keep : F32), c, s, poly, at_lattice(kx, step), at_lattice(kz, step), kx, kz, core, d, h),
        poly, U32.add(kx, 1), kz, step, keep, core, d)

def back_rows(fuel: Nat, +c: Ctx, s: St, +poly: List<&2, V>, +kx0: U32, +nx: Nat, +kz: U32, +step: F32, +keep: F32, +core: Bool, +d: F32) -> St:
  match fuel:
    case 0n:
      s
    case 1n+p:
      back_rows(p, c, back_cols(nx, c, s, poly, kx0, kz, step, keep, core, d), poly, kx0, nx, U32.add(kz, 1), step, keep, core, d)

def back_lat(l: Lat, +c: Ctx, +s: St, +poly: List<&2, V>, +step: F32, +keep: F32, +core: Bool, +d: F32) -> St:
  match l:
    case Lat{x0, z0, nx, nz}:
      back_rows(U32.to_nat(nz), c, s, poly, x0, U32.to_nat(nx), z0, step, keep, core, d)

def back_go(built: Bool, +c: Ctx, +s: St, +b: Ba) -> St:
  match built:
    case False{}:
      s
    case True{}:
      match b:
        case Ba{land, d, poly, last, box}:
          +core = Bool.and(U32.is_eq(land, 4), (d > 0.72 : F32))
          +keep = Bool.pick(F32, U32.is_eq(land, 6), 0.6, Bool.pick(F32, core, 0.5, 0.88))
          +step = Bool.pick(F32, core, 26.0, 11.0)
          back_lat(lattice(box, step), c, s, poly, step, keep, core, d)

def ba_land(+b: Ba) -> U32:
  match b:
    case Ba{land, d, poly, last, box}:
      land

def back_lots(bs: List<&2, Ba>, +c: Ctx, s: St) -> St:
  match bs:
    case Nil{}:
      s
    case Con{+b, r}:
      back_lots(r, c, back_go(U32.is_ge(ba_land(b), 2), c, s, b))

# ===========================================================================
# Trees
#
# Big round canopies only: mangga mostly, flamboyan on main roads, beringin
# now and then, bambu along the river. No palms.
# ===========================================================================

# How far a point stands beyond the nearest carriageway.
# Whether p stands at least `need` beyond every carriageway. A piece whose box, grown by its half width, the need and a metre, misses p
# is further than that, and is not measured.
def piece_clear(close: Bool, +p: V, +a: V, +b: V, +kind: U32, +need: F32) -> Bool:
  match close:
    case False{}:
      True{}
    case True{}:
      (F32.sqrt(point_seg2(p, a, b)) - road_half(kind) >= need : F32)

def clear_in(xs: List<&2, Item>, +p: V, +need: F32) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{+it, r}:
      match it:
        case ISol{what, pts, box}:
          clear_in(r, p, need)
        case ISeg{a, b, kind, sb}:
          +close = box_near(sb, p, (road_half(kind) + need + 1.0 : F32))
          Bool.and(piece_clear(close, p, a, b, kind, need), clear_in(r, p, need))

def clear_go(bs: List<&2, List<&2, Item>>, +p: V, +need: F32) -> Bool:
  match bs:
    case Nil{}:
      True{}
    case Con{+xs, r}:
      Bool.and(clear_in(xs, p, need), clear_go(r, p, need))

def road_clear(+c: Ctx, +p: V, +r: F32, +need: F32) -> Bool:
  clear_go(near(ctx_roads(c), around(p, (r + 16.0 : F32))), p, need)

# Whether a point is inside a solid of a kind below `upto`: lots (0), and
# courts too (1).
def solid_has(near: Bool, +pts: List<&2, V>, +p: V) -> Bool:
  match near:
    case False{}:
      False{}
    case True{}:
      in_poly(p, pts)

def in_what_in(xs: List<&2, Item>, +p: V, +upto: U32) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+it, r}:
      match it:
        case ISeg{a, b, kind, sb}:
          in_what_in(r, p, upto)
        case ISol{what, pts, box}:
          Bool.or(solid_has(Bool.and(U32.is_lt(what, upto), box_has(box, p)), pts, p), in_what_in(r, p, upto))

def in_what(bs: List<&2, List<&2, Item>>, +p: V, +upto: U32) -> Bool:
  match bs:
    case Nil{}:
      False{}
    case Con{+xs, r}:
      Bool.or(in_what_in(xs, p, upto), in_what(r, p, upto))

def lot_near_in(xs: List<&2, Item>, +b: Box) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+it, r}:
      match it:
        case ISeg{a, bb, kind, sb}:
          lot_near_in(r, b)
        case ISol{what, pts, box}:
          Bool.or(Bool.and(U32.is_eq(what, 0), boxes_meet(box, b)), lot_near_in(r, b))

def lot_near(bs: List<&2, List<&2, Item>>, +b: Box) -> Bool:
  match bs:
    case Nil{}:
      False{}
    case Con{+xs, r}:
      Bool.or(lot_near_in(xs, b), lot_near(r, b))

def river_piece(look: Bool, +p: V, +a: V, +b: V) -> Bool:
  match look:
    case False{}:
      False{}
    case True{}:
      (point_seg2(p, a, b) < 1024.0 : F32)

def river_near_in(xs: List<&2, Item>, +p: V) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+it, r}:
      match it:
        case ISol{what, pts, box}:
          river_near_in(r, p)
        case ISeg{a, b, kind, sb}:
          Bool.or(river_piece(Bool.and(U32.is_eq(kind, 0), box_near(sb, p, 33.0)), p, a, b), river_near_in(r, p))

def river_near(bs: List<&2, List<&2, Item>>, +p: V) -> Bool:
  match bs:
    case Nil{}:
      False{}
    case Con{+xs, r}:
      Bool.or(river_near_in(xs, p), river_near(r, p))

# ---- Street trees on the verges of main roads ------------------------------------

def court_has_in(xs: List<&2, Item>, +p: V) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+it, r}:
      match it:
        case ISeg{a, b, kind, sb}:
          court_has_in(r, p)
        case ISol{what, pts, box}:
          Bool.or(solid_has(Bool.and(U32.is_eq(what, 1), box_has(box, p)), pts, p), court_has_in(r, p))

def in_court(bs: List<&2, List<&2, Item>>, +p: V) -> Bool:
  match bs:
    case Nil{}:
      False{}
    case Con{+xs, r}:
      Bool.or(court_has_in(xs, p), in_court(r, p))

def verge_tree(ok: Bool, +s: St, +q: V, +h: F32) -> St:
  match ok:
    case False{}:
      s
    case True{}:
      add_tree(s, Tree{vx(q), vz(q), lerp(3.0, 4.5, h), Bool.pick(U32, (h > 0.88 : F32), 2, 0)})

def verge_check(inblock: Bool, +c: Ctx, +s: St, +q: V, +h: F32) -> St:
  match inblock:
    case False{}:
      s
    case True{}:
      +here = near(st_sol(s), around(q, 1.0))
      verge_tree(Bool.and(road_clear(c, q, 0.0, 1.2), Bool.not(in_court(here, q))), s, q, h)

def verge_go(go: Bool, +c: Ctx, +s: St, +rd: Rd, +side: F32, +at: F32, +h: F32) -> St:
  match go:
    case False{}:
      s
    case True{}:
      +q = off(rd_at(rd, at), 0.0, ((road_half(rd_kindof(rd)) + 1.6) * side : F32))
      verge_check(hit_found(block_at(ctx_blocks(c), q, Hit{False{}, 0, 0.0})), c, s, q, h)

def verge_walk(fuel: Nat, +c: Ctx, s: St, +rd: Rd, +n: U32, +side: F32, +k: U32) -> St:
  match fuel:
    case 0n:
      s
    case 1n+p:
      +at = (6.0 + f32(k) * 11.0 : F32)
      +h = r4(ctx_key(c), n, side_code(side), 5000, k)
      verge_walk(p, c, verge_go(Bool.and((at < rd_len(rd) - 6.0 : F32), (h >= 0.2 : F32)), c, s, rd, side, at, h), rd, n, side, U32.add(k, 1))

def verge_street(main: Bool, +c: Ctx, +s: St, +rd: Rd, +n: U32) -> St:
  match main:
    case False{}:
      s
    case True{}:
      +fuel = U32.to_nat(U32.add(floor_u((rd_len(rd) / 11.0 : F32)), 1))
      verge_walk(fuel, c, verge_walk(fuel, c, s, rd, n, 1.0, 0), rd, n, F32.neg(1.0), 0)

def verges(rs: List<&2, Rd>, +c: Ctx, +n: U32, s: St) -> St:
  match rs:
    case Nil{}:
      s
    case Con{+rd, r}:
      verges(r, c, U32.add(n, 1), verge_street(U32.is_ne(rd_kindof(rd), 3), c, s, rd, n))

# ---- The rest of the land, on a jittered lattice -----------------------------------

def species(+river: Bool, +land: U32, +roll: F32) -> U32:
  Bool.pick(U32, Bool.and(Bool.and(river, U32.is_ne(land, 1)), (roll < 0.6 : F32)), 3,
    pick_from([Cut{0.04, 1}, Cut{0.1, 2}], roll, 0))

def grow_tree(+s: St, +p: V, +r: F32, +river: Bool, +land: U32, +roll: F32) -> St:
  +sp = species(river, land, roll)
  +rr = Bool.pick(F32, U32.is_eq(sp, 1), (r + 2.5 : F32), Bool.pick(F32, U32.is_eq(sp, 3), (r * 0.7 : F32), r))
  add_tree(s, Tree{vx(p), vz(p), rr, sp})

def keep_if(keep: Bool, +s: St, +p: V, +r: F32, +river: Bool, +land: U32, +roll: F32) -> St:
  match keep:
    case False{}:
      s
    case True{}:
      grow_tree(s, p, r, river, land, roll)

# Bambu only grows by the river, outside kebun, on a low roll; nowhere else
# does the river matter, so it is looked for only then.
def river_for(look: Bool, +c: Ctx, +p: V) -> Bool:
  match look:
    case False{}:
      False{}
    case True{}:
      river_near(near(ctx_roads(c), around(p, 30.0)), p)

# Sawah keeps a tree by the river, then by a lot, then in a clump.
def sawah_by_lot(look: Bool, +c: Ctx, +s: St, +p: V, +r: F32, +h: F32, +roll: F32) -> St:
  match look:
    case False{}:
      s
    case True{}:
      +key = ctx_key(c)
      +clump = (r3(key, 53, floor_u(((vx(p) + 1000.0) / 70.0 : F32)), floor_u(((vz(p) + 1000.0) / 70.0 : F32))) < 0.14 : F32)
      +by_lot = lot_near(near(st_sol(s), around(p, 14.0)), around(p, 14.0))
      keep_if((h < Bool.pick(F32, by_lot, 0.8, Bool.pick(F32, clump, 0.85, 0.0)) : F32), s, p, r, False{}, 0, roll)

def sawah_keep(river: Bool, +c: Ctx, +s: St, +p: V, +r: F32, +h: F32, +roll: F32) -> St:
  match river:
    case True{}:
      keep_if((h < 0.6 : F32), s, p, r, True{}, 0, roll)
    case False{}:
      sawah_by_lot((h < 0.85 : F32), c, s, p, r, h, roll)

def land_tree(sawah: Bool, +c: Ctx, +s: St, +p: V, +r: F32, +land: U32, +core: Bool, +h: F32, +roll: F32) -> St:
  match sawah:
    case True{}:
      sawah_keep(river_for(True{}, c, p), c, s, p, r, h, roll)
    case False{}:
      +keep = Bool.pick(F32, U32.is_eq(land, 1), 0.92, Bool.pick(F32, core, 0.2, Bool.pick(F32, U32.is_eq(land, 6), 0.55, 0.8)))
      +kept = (h < keep : F32)
      keep_if(kept, s, p, r, river_for(Bool.and(kept, Bool.and(U32.is_ne(land, 1), (roll < 0.6 : F32))), c, p), land, roll)

def canopy_keep(free: Bool, +c: Ctx, +s: St, +p: V, +r: F32, +kx: U32, +kz: U32, +land: U32, +core: Bool) -> St:
  match free:
    case False{}:
      s
    case True{}:
      +key = ctx_key(c)
      land_tree(U32.is_eq(land, 0), c, s, p, r, land, core, r3(key, 54, kx, kz), r3(key, 55, kx, kz))

def canopy_gap(clear: Bool, +c: Ctx, +s: St, +p: V, +r: F32, +kx: U32, +kz: U32, +land: U32, +core: Bool) -> St:
  match clear:
    case False{}:
      s
    case True{}:
      +here = near(st_sol(s), around(p, 1.0))
      canopy_keep(Bool.not(in_what(here, p, 2)), c, s, p, r, kx, kz, land, core)

def canopy_in(inside: Bool, +c: Ctx, +s: St, +p: V, +kx: U32, +kz: U32, +land: U32, +core: Bool) -> St:
  match inside:
    case False{}:
      s
    case True{}:
      +r = lerp(3.0, 5.8, r3(ctx_key(c), 52, kx, kz))
      canopy_gap(road_clear(c, p, r, (r * 0.5 + 1.0 : F32)), c, s, p, r, kx, kz, land, core)

def canopy_cols(fuel: Nat, +c: Ctx, s: St, +poly: List<&2, V>, +kx: U32, +kz: U32, +step: F32, +land: U32, +core: Bool) -> St:
  match fuel:
    case 0n:
      s
    case 1n+p:
      +key = ctx_key(c)
      +q = {V{(at_lattice(kx, step) + (r3(key, 50, kx, kz) - 0.5) * step * 0.8 : F32), (at_lattice(kz, step) + (r3(key, 51, kx, kz) - 0.5) * step * 0.8 : F32)} : V}
      canopy_cols(p, c, canopy_in(in_poly(q, poly), c, s, q, kx, kz, land, core), poly, U32.add(kx, 1), kz, step, land, core)

def canopy_rows(fuel: Nat, +c: Ctx, s: St, +poly: List<&2, V>, +kx0: U32, +nx: Nat, +kz: U32, +step: F32, +land: U32, +core: Bool) -> St:
  match fuel:
    case 0n:
      s
    case 1n+p:
      canopy_rows(p, c, canopy_cols(nx, c, s, poly, kx0, kz, step, land, core), poly, kx0, nx, U32.add(kz, 1), step, land, core)

def canopy_lat(l: Lat, +c: Ctx, +s: St, +poly: List<&2, V>, +step: F32, +land: U32, +core: Bool) -> St:
  match l:
    case Lat{x0, z0, nx, nz}:
      canopy_rows(U32.to_nat(nz), c, s, poly, x0, U32.to_nat(nx), z0, step, land, core)

def canopies(bs: List<&2, Ba>, +c: Ctx, s: St) -> St:
  match bs:
    case Nil{}:
      s
    case Con{+b, r}:
      match b:
        case Ba{land, d, poly, last, box}:
          +step = Bool.pick(F32, U32.is_eq(land, 1), 6.5, 7.0)
          canopies(r, c, canopy_lat(lattice(box, step), c, s, poly, step, land, Bool.and(U32.is_eq(land, 4), (d > 0.72 : F32))))

# ===========================================================================
# One cell's parcels
# ===========================================================================

# Everything is metres from the cell's first corner, which is (ox, oz) in
# world centimetres.
type Plan is Data:
  Plan{ox: U32, oz: U32, lots: List<&2, Lot>, courts: List<&2, Court>, trees: List<&2, Tree>}

def corner_of(+f: W.Frame) -> W.Pt:
  match f:
    case W.Frame{a, s, n, w, e, mu, mv}:
      a

def plan_of(+o: W.Pt, s: St) -> Plan:
  match s:
    case St{sol, lots, courts, trees}:
      Plan{W.pt_x(o), W.pt_z(o), List.reverse(&2, Lot, lots), List.reverse(&2, Court, courts), List.reverse(&2, Tree, trees)}

def cell_parcels(c: W.Cell, +seed: U32, +i: U32, +j: U32) -> Plan:
  match c:
    case W.Cell{+f, +lines, +blocks}:
      +o = corner_of(f)
      +ws = List.append(&2, Way, ways(lines, o),
              List.append(&2, Way, far_road(W.has_road(seed, i, U32.add(j, 1), True{}), seed, i, U32.add(j, 1), True{}, o),
                far_road(W.has_road(seed, U32.add(i, 1), j, False{}), seed, U32.add(i, 1), j, False{}, o)))
      # Main roads first, so shops claim the corners.
      +streets = List.append(&2, Rd, streets_of(ws, 1), List.append(&2, Rd, streets_of(ws, 2), streets_of(ws, 3)))
      +bs = areas(blocks, f, o)
      +key = W.hash3(seed, 40, i, j)
      +ctx = {Ctx{key, index_ways(ws, tr_empty(10n)), bs, streets} : Ctx}
      +s0 = blk_courts(blocks, key, f, o, St{tr_empty(10n), Nil{}, Nil{}, Nil{}})
      plan_of(o, canopies(bs, ctx, verges(streets, ctx, 0, back_lots(bs, ctx, frontage(streets, ctx, 0, civics(streets, ctx, 0, s0))))))

def parcels_of(+seed: U32, +i: U32, +j: U32) -> Plan:
  cell_parcels(W.cell_of(seed, i, j), seed, i, j)
