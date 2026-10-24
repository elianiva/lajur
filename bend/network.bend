# lajur — the road network and the signs on it: PP 79/2013, PM 111/2015,
# PM 13/2014.
import Base
import ./model.bend as M

# ---------------------------------------------------------------------------
# PP 79/2013 — functions of a road
# ---------------------------------------------------------------------------

# Pasal 10 to 12: the four functions, from the long-distance artery down to the
# street serving the houses on it.
def carries_long_distance(f: M.RoadFunction) -> Bool:
  match f:
    case M.Arteri{}:
      True{}
    case M.Kolektor{}:
      False{}
    case M.Lokal{}:
      False{}
    case M.Lingkungan{}:
      False{}

def functions() -> List<M.RoadFunction>:
  [ M.Arteri{}, M.Kolektor{}, M.Lokal{}, M.Lingkungan{} ]

# Pasal 21: the class of a stretch is published on a sign, not in a map.
def class_is_signed() -> Bool:
  True{}

# Pasal 19: a heavier axle is what separates class I from the rest.
# ---------------------------------------------------------------------------
# PM 111/2015 — where a speed limit comes from
# ---------------------------------------------------------------------------

# Pasal 3 ayat (5): a limit binds only once a sign says so.
def limit_needs_a_sign() -> Bool:
  True{}

# Pasal 7 ayat (1): the four grounds for lowering a limit are closed; nothing
# else may be used to post a lower number.
def leaf_sizes() -> U32:
  4

# Pasal 34 and 35: a sign stands to the left of the traffic it governs, 60 cm
# from the outer shoulder, or 30 cm from the median edge.
def shoulder_clearance_cm() -> U32:
  60

def median_clearance_cm() -> U32:
  30

# Pasal 5 ayat (3): every conventional leaf carries the transport logo sticker.
def leaf_needs_logo() -> Bool:
  True{}

# Pasal 21: a route number for a national, provincial or municipal road is a
# white hexagon with black digits; the Asian Highway number is a rectangle.
def route_number_sides(national: Bool) -> U32:
  match national:
    case True{}:
      6
    case False{}:
      4

# The five colours a guidance sign may use, by purpose.
def tourism_base_is_brown() -> M.Colour:
  M.Brown{}

# ---------------------------------------------------------------------------
# PM 13/2014 — how high a sign hangs, and how far before a hazard it stands
# ---------------------------------------------------------------------------

# Pasal 36 ayat (1): the bottom of the leaf, or of its supplement, sits between
# 175 and 265 cm above the highest point of the road.
def sign_min_height_cm() -> U32:
  175

def sign_max_height_cm() -> U32:
  265

# Pasal 36 ayat (3): a curve chevron sits lower, at 120 cm.
def chevron_height_cm() -> U32:
  120

# Pasal 36 ayat (4): a sign over the road clears 500 cm.
def overhead_min_height_cm() -> U32:
  500

# Pasal 39: the faster the design speed, the earlier the warning.
def warning_distance_60(fast: Bool, +speed: U32) -> U32:
  match fast:
    case True{}:
      80
    case False{}:
      50

def warning_distance_80(fast: Bool, +speed: U32) -> U32:
  match fast:
    case True{}:
      100
    case False{}:
      warning_distance_60(U32.is_gt(speed, 60), speed)

def warning_distance_100(fast: Bool, +speed: U32) -> U32:
  match fast:
    case True{}:
      180
    case False{}:
      warning_distance_80(U32.is_gt(speed, 80), speed)

def warning_distance_m(+speed: U32) -> U32:
  warning_distance_100(U32.is_gt(speed, 100), speed)

def warning_stands_before_the_hazard() -> Bool:
  True{}

# Pasal 42 ayat (3): a parking or stopping ban reaches 30 m from the sign.
def parking_ban_extent_m() -> U32:
  30

def prohibition_starts_at_the_ban() -> Bool:
  True{}

def command_stands_at_the_order() -> Bool:
  True{}

# Pasal 54 ayat (1): a supplement sits 5 to 10 cm below the leaf.
def supplement_gap_min_cm() -> U32:
  5

def supplement_gap_max_cm() -> U32:
  10

# Pasal 54 ayat (2): the supplement is twice as wide as it is tall.
def supplement_ratio_wide() -> U32:
  2

def supplement_ratio_tall() -> U32:
  1

# Pasal 54 ayat (3): five kinds of sign may not carry a supplement.
def supplement_forbidden_count() -> U32:
  5

# Pasal 30 ayat (3): a supplement is white with a black border.
def supplement_base() -> M.Colour:
  M.White{}

def supplement_border() -> M.Colour:
  M.Black{}

# Pasal 64 ayat (1): one pole carries at most two leaves.
def max_leaves_per_pole() -> U32:
  2

def sign_may_not_be_obstructed() -> Bool:
  True{}

# Pasal 67 ayat (2): a sign is maintained at least every six months.
def maintenance_months() -> U32:
  6

# Pasal 68 ayat (2): a sign's technical life is at most five years.
def technical_life_years() -> U32:
  5

# Pasal 37: the leaf size follows the design speed.
type LeafSize is Data:
  LeafSmall{}
  LeafMedium{}
  LeafLarge{}
  LeafVeryLarge{}

def leaf_size_medium(medium: Bool, +speed: U32) -> LeafSize:
  match medium:
    case True{}:
      LeafMedium{}
    case False{}:
      LeafSmall{}

def leaf_size_large(large: Bool, +speed: U32) -> LeafSize:
  match large:
    case True{}:
      LeafLarge{}
    case False{}:
      leaf_size_medium(U32.is_gt(speed, 30), speed)

def leaf_size_fast(fast: Bool, +speed: U32) -> LeafSize:
  match fast:
    case True{}:
      LeafVeryLarge{}
    case False{}:
      leaf_size_large(U32.is_gt(speed, 60), speed)

def leaf_size_for(+speed: U32) -> LeafSize:
  leaf_size_fast(U32.is_gt(speed, 80), speed)

def same_leaf_size(a: LeafSize, b: LeafSize) -> Bool:
  match a:
    case LeafSmall{}:
      match b:
        case LeafSmall{}:
          True{}
        case _:
          False{}
    case LeafMedium{}:
      match b:
        case LeafMedium{}:
          True{}
        case _:
          False{}
    case LeafLarge{}:
      match b:
        case LeafLarge{}:
          True{}
        case _:
          False{}
    case LeafVeryLarge{}:
      match b:
        case LeafVeryLarge{}:
          True{}
        case _:
          False{}


def count_functions(xs: List<M.RoadFunction>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_functions(t))

def function_count() -> U32:
  count_functions(functions())

# A class I road takes a vehicle a class III road turns away.
def class_admits_more() -> Bool:
  Bool.and(M.class_admits(M.ClassIII{}, 2100, 9000, 3500, 8),
  Bool.and(Bool.not(M.class_admits(M.ClassIII{}, 2500, 9000, 3500, 8)),
           M.class_admits(M.ClassI{}, 2500, 18000, 4200, 10)))
