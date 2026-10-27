# lajur — the town: A junction: its shape, its duty, its signals, furniture and box.
# Part of town.bend, which names the town's functions for the page.
import Base
import ./lattice.bend as Lat
import ./streets.bend as Str

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
  shape_of(Str.branches(i, j),
           differ(Lat.major_col(i), Lat.major_row(j)),
           Str.through(i, j, Str.missing_of(Str.has(i, j, Str.North{}), Str.has(i, j, Str.East{}),
                                    Str.has(i, j, Str.South{}), Str.has(i, j, Str.West{})), seed))

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
  +crossing = Bool.and(Lat.major_col(i), Lat.major_row(j))
  +wide = U32.is_le(3, Str.branches(i, j))
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
      +i = U32.mod(n, Lat.cols())
      +j = U32.div(n, Lat.cols())
      Bool.and(U32.is_le(2, Str.branches(i, j)), every_node_wide(p, U32.add(n, 1)))

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

def green_of(c: Control, d: Str.Dir, tick: U32) -> Bool:
  match c:
    case Signal{}:
      match d:
        case Str.North{}:
          green_at(0, tick)
        case Str.South{}:
          green_at(0, tick)
        case Str.East{}:
          green_at(1, tick)
        case Str.West{}:
          green_at(1, tick)
    case Roundabout{}:
      True{}
    case Uncontrolled{}:
      True{}

def green(i: U32, j: U32, d: Str.Dir, tick: U32) -> Bool:
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
def street_of(+i: U32, +j: U32, d: Str.Dir) -> Street:
  match d:
    case Str.East{}:
      row_street(U32.is_eq(j, 0), U32.is_eq(j, U32.sub(Lat.rows(), 1)), Lat.major_row(j))
    case Str.West{}:
      row_street(U32.is_eq(j, 0), U32.is_eq(j, U32.sub(Lat.rows(), 1)), Lat.major_row(j))
    case Str.North{}:
      row_street(U32.is_eq(i, 0), U32.is_eq(i, U32.sub(Lat.cols(), 1)), Lat.major_col(i))
    case Str.South{}:
      row_street(U32.is_eq(i, 0), U32.is_eq(i, U32.sub(Lat.cols(), 1)), Lat.major_col(i))

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
  Bool.or(Bool.or(U32.is_eq(i, 0), U32.is_eq(i, U32.sub(Lat.cols(), 1))),
          Bool.or(U32.is_eq(j, 0), U32.is_eq(j, U32.sub(Lat.rows(), 1))))

# Two local streets, a collector, or the ring.
def junction_rank(+i: U32, +j: U32) -> U32:
  Bool.pick(U32, ring_here(i, j), 2,
            Bool.pick(U32, Bool.or(Lat.major_col(i), Lat.major_row(j)), 1, 0))

def junction_radius_cm(+i: U32, +j: U32, +seed: U32) -> U32:
  +base = U32.add(600, U32.mul(150, junction_rank(i, j)))
  +band = U32.add(150, U32.mul(75, junction_rank(i, j)))
  U32.add(base, U32.mod(Lat.mix(U32.add(i, 31), U32.add(j, 977)), band))

def widest(a: Bool, ah: U32, b: Bool, bh: U32) -> U32:
  U32.max(Bool.pick(U32, a, ah, 0), Bool.pick(U32, b, bh, 0))

# The widest street whose kerb cuts this approach: the one across the node.
def cross_half(+i: U32, +j: U32, +d: Str.Dir) -> U32:
  match d:
    case Str.North{}:
      widest(Str.has(i, j, Str.East{}), half_cm(street_of(i, j, Str.East{})),
             Str.has(i, j, Str.West{}), half_cm(street_of(i, j, Str.West{})))
    case Str.South{}:
      widest(Str.has(i, j, Str.East{}), half_cm(street_of(i, j, Str.East{})),
             Str.has(i, j, Str.West{}), half_cm(street_of(i, j, Str.West{})))
    case Str.East{}:
      widest(Str.has(i, j, Str.North{}), half_cm(street_of(i, j, Str.North{})),
             Str.has(i, j, Str.South{}), half_cm(street_of(i, j, Str.South{})))
    case Str.West{}:
      widest(Str.has(i, j, Str.North{}), half_cm(street_of(i, j, Str.North{})),
             Str.has(i, j, Str.South{}), half_cm(street_of(i, j, Str.South{})))

# How far from the node an approach's kerb stops.
def mouth_cm(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> U32:
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
  Approach{d: Str.Dir, present: Bool, half: U32, mark: Mark, line_cm: U32, zebra_cm: U32,
           head: Bool, post: Post}

def opposite(d: Str.Dir) -> Str.Dir:
  match d:
    case Str.North{}:
      Str.South{}
    case Str.South{}:
      Str.North{}
    case Str.East{}:
      Str.West{}
    case Str.West{}:
      Str.East{}

def is_eq_dir(a: Str.Dir, b: Str.Dir) -> Bool:
  match a:
    case Str.North{}:
      match b:
        case Str.North{}:
          True{}
        case _:
          False{}
    case Str.South{}:
      match b:
        case Str.South{}:
          True{}
        case _:
          False{}
    case Str.East{}:
      match b:
        case Str.East{}:
          True{}
        case _:
          False{}
    case Str.West{}:
      match b:
        case Str.West{}:
          True{}
        case _:
          False{}

def minor_of(+i: U32, +j: U32, d: Str.Dir) -> Bool:
  match d:
    case Str.North{}:
      Bool.not(Lat.major_col(i))
    case Str.South{}:
      Bool.not(Lat.major_col(i))
    case Str.East{}:
      Bool.not(Lat.major_row(j))
    case Str.West{}:
      Bool.not(Lat.major_row(j))

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

def approach_of(d: Str.Dir, present: Bool, +half: U32, +behind: U32, street: Street, +c: Control,
                +gives: Bool, +given: Bool) -> Approach:
  Approach{d, present, half, mark_of(c, gives), line_cm(behind), crossing_cm(c, street, behind),
           signal_head(c), post_of(c, gives, given)}

def approach_at(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> Approach:
  +c = control(i, j)
  +s = shape(i, j, seed)
  +street = street_of(i, j, d)
  +gone = Str.missing_of(Str.has(i, j, Str.North{}), Str.has(i, j, Str.East{}),
                     Str.has(i, j, Str.South{}), Str.has(i, j, Str.West{}))
  +stem = is_eq_dir(d, opposite(gone))
  +gives = gives_way(s, minor_of(i, j, d), stem)
  +given = Bool.and(has_give_way(c, s), Bool.not(gives))
  approach_of(d, Str.has(i, j, d), half_cm(street), mouth_cm(i, j, d, seed), street, c, gives, given)

# The four approaches of a junction. One that has no street is still answered,
# so the list is the same shape everywhere and the renderer can walk it.
def approaches(+i: U32, +j: U32, +seed: U32) -> List<Approach>:
  [ approach_at(i, j, Str.North{}, seed)
  , approach_at(i, j, Str.East{}, seed)
  , approach_at(i, j, Str.South{}, seed)
  , approach_at(i, j, Str.West{}, seed)
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

def gives_of(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> Bool:
  +gone = Str.missing_of(Str.has(i, j, Str.North{}), Str.has(i, j, Str.East{}),
                     Str.has(i, j, Str.South{}), Str.has(i, j, Str.West{}))
  gives_way(shape(i, j, seed), minor_of(i, j, d), is_eq_dir(d, opposite(gone)))

def line_in(a: Approach) -> U32:
  match a:
    case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
      line_cm

def line_at(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> U32:
  line_in(approach_at(i, j, d, seed))

def mark_at(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> Mark:
  mark_of(control(i, j), gives_of(i, j, d, seed))

def post_in(a: Approach) -> Post:
  match a:
    case Approach{d, present, half, mark, line_cm, zebra_cm, head, post}:
      post

def post_at(+i: U32, +j: U32, +d: Str.Dir, +seed: U32) -> Post:
  post_in(approach_at(i, j, d, seed))
