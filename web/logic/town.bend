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
#
# The model is in logic/town/, one module per layer, each importing only the
# layers beneath it: lattice, streets, junction, blocks, pavement, split. This
# file names the functions the page and the scripts call, so that town.mjs
# keeps a flat list of them; PROOF.bend proves the layers directly.
import Base
import ./town/lattice.bend as Lat
import ./town/streets.bend as Str
import ./town/junction.bend as Jun
import ./town/blocks.bend as Blk
import ./town/pavement.bend as Pav
import ./town/split.bend as Spl

def bridge(+j: U32) -> Bool:
  Lat.bridge(j)

def cols() -> U32:
  Lat.cols()

def margin_cm() -> U32:
  Lat.margin_cm()

def pitch_cm() -> U32:
  Lat.pitch_cm()

def river_gap() -> U32:
  Lat.river_gap()

def rows() -> U32:
  Lat.rows()

def seed_of_town() -> U32:
  Lat.seed_of_town()

def site(+i: U32, +j: U32, +seed: U32) -> Lat.Pt:
  Lat.site(i, j, seed)

def has(+i: U32, +j: U32, d: Str.Dir) -> Bool:
  Str.has(i, j, d)

def samples(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> List<Str.Sample>:
  Str.samples(i, j, d, seed)

def approaches(+i: U32, +j: U32, +seed: U32) -> List<Jun.Approach>:
  Jun.approaches(i, j, seed)

def control(+i: U32, +j: U32) -> Jun.Control:
  Jun.control(i, j)

def junction_radius_cm(+i: U32, +j: U32, +seed: U32) -> U32:
  Jun.junction_radius_cm(i, j, seed)

def mouth_cm(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> U32:
  Jun.mouth_cm(i, j, d, seed)

def shape(+i: U32, +j: U32, +seed: U32) -> Jun.Shape:
  Jun.shape(i, j, seed)

def block_exists(+i: U32, +j: U32) -> Bool:
  Blk.block_exists(i, j)

def core_at(+i: U32, +j: U32, +u: U32, +v: U32, +seed: U32) -> Lat.Pt:
  Blk.core_at(i, j, u, v, seed)

def core_lot_at(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Blk.Lot:
  Blk.core_lot_at(i, j, a, b, seed)

def core_lots_d(+i: U32, +j: U32, +seed: U32) -> U32:
  Blk.core_lots_d(i, j, seed)

def core_lots_w(+i: U32, +j: U32, +seed: U32) -> U32:
  Blk.core_lots_w(i, j, seed)

def core_open(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Bool:
  Blk.core_open(i, j, a, b, seed)

def gang_cm() -> U32:
  Blk.gang_cm()

def lot_at(+i: U32, +j: U32, +side: U32, +ring: U32, +t: U32, +seed: U32) -> Blk.Lot:
  Blk.lot_at(i, j, side, ring, t, seed)

def lots_on(+i: U32, +j: U32, +side: U32, +ring: U32, +seed: U32) -> U32:
  Blk.lots_on(i, j, side, ring, seed)

def pavement_cm() -> U32:
  Blk.pavement_cm()

def rings_in(+i: U32, +j: U32, +seed: U32) -> U32:
  Blk.rings_in(i, j, seed)

def row_depth_cm() -> U32:
  Blk.row_depth_cm()

def core_tree(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Pav.Prop:
  Pav.core_tree(i, j, a, b, seed)

def corner_between(+i: U32, +j: U32, +a: Str.Dir, +b: Str.Dir, +seed: U32) -> Lat.Pt:
  Pav.corner_between(i, j, a, b, seed)

def mouth_mid(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> Lat.Pt:
  Pav.mouth_mid(i, j, d, seed)

def mouth_side(+i: U32, +j: U32, +d: Str.Dir, +left: Bool, +seed: U32) -> Lat.Pt:
  Pav.mouth_side(i, j, d, left, seed)

def prop_at(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Pav.Prop:
  Pav.prop_at(i, j, side, t, seed)

def core_lot_built(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Bool:
  Spl.core_lot_built(i, j, a, b, seed)

def core_tree_built(+i: U32, +j: U32, +a: U32, +b: U32, +seed: U32) -> Bool:
  Spl.core_tree_built(i, j, a, b, seed)

def cut_steps() -> U32:
  Spl.cut_steps()

def lot_built(+i: U32, +j: U32, +side: U32, +ring: U32, +t: U32, +seed: U32) -> Bool:
  Spl.lot_built(i, j, side, ring, t, seed)

def patch(+i: U32, +j: U32, +u: U32, +v: U32, +seed: U32) -> Lat.Pt:
  Spl.patch(i, j, u, v, seed)

def prop_built(+i: U32, +j: U32, +side: U32, +t: U32, +seed: U32) -> Bool:
  Spl.prop_built(i, j, side, t, seed)

def rect_of(+i: U32, +j: U32, +p: U32, +seed: U32) -> Spl.Rect:
  Spl.rect_of(i, j, p, seed)

def split_code(+i: U32, +j: U32, +p: U32, +seed: U32) -> U32:
  Spl.split_code(i, j, p, seed)

def split_point(+i: U32, +j: U32, +p: U32, +k: U32, +seed: U32) -> Lat.Pt:
  Spl.split_point(i, j, p, k, seed)
