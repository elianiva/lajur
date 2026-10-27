# lajur — the town: The pavement: one prop in front of every frontage lot.
# Part of town.bend, which names the town's functions for the page.
import Base
import ./lattice.bend as Lat
import ./streets.bend as Str
import ./junction.bend as Jun
import ./blocks.bend as Blk

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
  U32.add(Jun.half_cm(Jun.street_of(Blk.side_i(i, side), Blk.side_j(j, side), Blk.side_dir(side))), 50)

# Within twenty metres of a junction only low planting stands. The lot is
# measured from the node, not from the end of the frontage, because the mouth
# already stands a kerb return and half the crossing street away from it.
def prop_low(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Bool:
  +w = Blk.lot_width(i, j, side, 0, seed)
  +at = U32.add(U32.mul(t, w), U32.shrn(w, 1n))
  +near = Jun.mouth_cm(Blk.side_i(i, side), Blk.side_j(j, side), Blk.side_dir(side), seed)
  +far = Jun.mouth_cm(Blk.far_i(i, side), Blk.far_j(j, side), Jun.opposite(Blk.side_dir(side)), seed)
  Bool.or(U32.is_lt(U32.add(near, at), 2200),
          U32.is_lt(U32.add(far, U32.sub(Blk.frontage_cm(i, j, side, 0, seed), at)), 2200))

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
  +roll = U32.mod(Lat.mix(U32.add(t, U32.mul(side, 17)), U32.add(seed, U32.mul(i, 13))), 100)
  prop_pick(prop_low(i, j, side, t, seed), prop_pole(side, t), roll)

type Prop is Data:
  Prop{x: U32, z: U32, r: U32, kind: PropKind}

def push_out(p: Lat.Pt, +f: Blk.Frame, +side: U32, +reach: U32) -> Lat.Pt:
  match p:
    case Lat.Pt{px, pz}:
      Lat.Pt{Blk.push_along(px, Blk.negate(Blk.inward_x(f, side)), reach),
         Blk.push_along(pz, Blk.negate(Blk.inward_z(f, side)), reach)}

# The prop in front of lot t of a frontage: the lot's centre line, moved back
# out to the planting line.
def prop_at(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Prop:
  +mid = U32.shrn(U32.add(Blk.lot_edge_t(i, j, side, 0, t, seed),
                        Blk.lot_edge_t(i, j, side, 0, U32.add(t, 1), seed)), 1n)
  +kind = prop_kind(i, j, side, t, seed)
  +c = Str.curve_of(Blk.side_i(i, side), Blk.side_j(j, side), Blk.side_dir(side), seed)
  +here = Blk.advance(Str.at(c, mid), Blk.frame_on(c, side, mid), prop_off_cm(i, j, side))
  Prop{Lat.pt_x(here), Lat.pt_z(here), crown_cm(kind), kind}

# A prop stands between the kerb and the far side of the pavement: never in the
# carriageway, never where the buildings begin.
def prop_on_pavement(+i: U32, +j: U32, +side: U32) -> Bool:
  +half = Jun.half_cm(Jun.street_of(Blk.side_i(i, side), Blk.side_j(j, side), Blk.side_dir(side)))
  Bool.and(U32.is_lt(half, prop_off_cm(i, j, side)),
           U32.is_lt(prop_off_cm(i, j, side), U32.add(half, Blk.pavement_cm())))

# Where the tree of an open cell stands: the middle of the cell, and a kind
# drawn from the cell's own roll, so the shade in a block is not one species.
def core_tree_kind(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> PropKind:
  +roll = U32.mod(Lat.mix(U32.add(a, U32.mul(b, 29)),
                     U32.add(seed, U32.add(U32.mul(i, 7), U32.mul(j, 23)))), 100)
  Bool.pick(PropKind, U32.is_lt(roll, 40), Mangga{},
            Bool.pick(PropKind, U32.is_lt(roll, 70), Palm{}, Kamboja{}))

def core_tree(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Prop:
  +nw = Blk.core_lots_w(i, j, seed)
  +nd = Blk.core_lots_d(i, j, seed)
  +u = U32.shrn(U32.add(Blk.core_edge(a, i, j, seed, True{}, nw),
                       Blk.core_edge(U32.add(a, 1), i, j, seed, True{}, nw)), 1n)
  +v = U32.shrn(U32.add(Blk.core_edge(b, i, j, seed, False{}, nd),
                       Blk.core_edge(U32.add(b, 1), i, j, seed, False{}, nd)), 1n)
  +kind = core_tree_kind(i, j, a, b, seed)
  +p = Blk.core_at(i, j, u, v, seed)
  Prop{Lat.pt_x(p), Lat.pt_z(p), crown_cm(kind), kind}

# Every prop of a frontage, walked by counting lots up: two crowns are narrower
# than the lot between them, and a tree never stands near a junction.
def props_apart(fuel: Nat, +t: U32, +i: U32, +j: U32, +side: U32, +seed: U32) -> Bool:
  match fuel:
    case 0n:
      True{}
    case 1n+p:
      +next = U32.add(t, 1)
      +live = U32.is_lt(next, Blk.lots_on(i, j, side, 0, seed))
      +pair = U32.add(crown_cm(prop_kind(i, j, side, t, seed)),
                      crown_cm(prop_kind(i, j, side, next, seed)))
      +ok = Bool.or(Bool.not(live), U32.is_le(pair, Blk.lot_width(i, j, side, 0, seed)))
      Bool.and(ok, props_apart(p, next, i, j, side, seed))

# The frame of an approach: its own street's chord from the node, and the
# perpendicular to it, which is the left of travel. A mouth is square to the
# street it belongs to, not to the block beside it, so each approach brings its
# own frame.
def approach_frame(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> Blk.Frame:
  Blk.frame_from(Lat.site(i, j, seed), Str.end_of(i, j, d, seed))

def mouth_at(f: Blk.Frame, +m: U32, +h: U32, +left: Bool) -> Lat.Pt:
  match f:
    case Blk.Frame{origin, +ux, +uz, +nx, +nz}:
      match origin:
        case Lat.Pt{ox, oz}:
          +sx = Bool.pick(Lat.Signed, left, Blk.negate(nx), nx)
          +sz = Bool.pick(Lat.Signed, left, Blk.negate(nz), nz)
          Lat.Pt{Blk.push_along(Blk.push_along(ox, ux, m), sx, h), Blk.push_along(Blk.push_along(oz, uz, m), sz, h)}

# One end of an approach's mouth: the point where its kerb stops.
def mouth_side(+i: U32, +j: U32, +d: Str.Dir, +left: Bool, +seed: U32) -> Lat.Pt:
  mouth_at(approach_frame(i, j, d, seed), Jun.mouth_cm(i, j, d, seed),
           Jun.half_cm(Jun.street_of(i, j, d)), left)

def mouth_mid(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> Lat.Pt:
  mouth_at(approach_frame(i, j, d, seed), Jun.mouth_cm(i, j, d, seed), 0, True{})

def corner_in(here: Lat.Pt, own: Blk.Frame, side: Blk.Frame, +h_side: U32, +h_own: U32) -> Lat.Pt:
  match here:
    case Lat.Pt{ox, oz}:
      match own:
        case Blk.Frame{origin, +ux, +uz, nx, nz}:
          match side:
            case Blk.Frame{origin2, +sx, +sz, nx2, nz2}:
              Lat.Pt{Blk.push_along(Blk.push_along(ox, ux, h_side), sx, h_own),
                 Blk.push_along(Blk.push_along(oz, uz, h_side), sz, h_own)}

# Where the two kerbs of a corner would meet if the return were square: the
# control point of the fillet that rounds it. It is reached by taking b's half
# along a and a's half along b, so the corner is the same point from either
# side of it.
def corner_between(+i: U32, +j: U32, +a: Str.Dir, +b: Str.Dir, +seed: U32) -> Lat.Pt:
  corner_in(Lat.site(i, j, seed), approach_frame(i, j, a, seed), approach_frame(i, j, b, seed),
            Jun.half_cm(Jun.street_of(i, j, b)), Jun.half_cm(Jun.street_of(i, j, a)))

def corner_pt(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> Lat.Pt:
  corner_between(i, j, d, Str.left_of(d), seed)
