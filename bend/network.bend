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
