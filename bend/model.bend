# lajur — the vocabulary the laws share: which instruments exist, and the
# numeric tables they state. Content only; no scenario logic.
import Base

# ---------------------------------------------------------------------------
# Instruments
# ---------------------------------------------------------------------------

type Inst is Data:
  UU22{}
  UU28{}
  PP30{}
  PP37{}
  PP79{}
  PM13{}
  PM111{}
  Perpol5{}
def instruments() -> List<Inst>:
  [ UU22{}, UU28{}, PP30{}, PP37{}, PP79{}, PM13{}, PM111{}, Perpol5{} ]

# ---------------------------------------------------------------------------
# Speed, PM 111/2015 Pasal 3 ayat (4)
# ---------------------------------------------------------------------------

type Zone is Data:
  Residential{}
  Urban{}
  Intercity{}
  Motorway{}

def speed_limit(z: Zone) -> U32:
  match z:
    case Residential{}:
      30
    case Urban{}:
      50
    case Intercity{}:
      80
    case Motorway{}:
      100

# A motorway is the only road with a floor as well as a ceiling.
def speed_floor(z: Zone) -> U32:
  match z:
    case Residential{}:
      0
    case Urban{}:
      0
    case Intercity{}:
      0
    case Motorway{}:
      60

# Pasal 7 ayat (1): four grounds lower a limit below the national ceiling.
type Ground is Data:
  Accidents{}
  Surface{}
  Geometry{}
  Community{}
def accident_window_years() -> U32:
  3

# ---------------------------------------------------------------------------
# Signs, PM 13/2014 Pasal 3, 10, 13, 17, 20, 28, 30
# ---------------------------------------------------------------------------

type Sign is Data:
  Warning{}
  Prohibition{}
  Command{}
  Guidance{}

type Colour is Data:
  Yellow{}
  Red{}
  Blue{}
  Green{}
  Brown{}
  Orange{}
  White{}
  Black{}

def sign_base(s: Sign) -> Colour:
  match s:
    case Warning{}:
      Yellow{}
    case Prohibition{}:
      White{}
    case Command{}:
      Blue{}
    case Guidance{}:
      Green{}

def sign_border(s: Sign) -> Colour:
  match s:
    case Warning{}:
      Black{}
    case Prohibition{}:
      Red{}
    case Command{}:
      White{}
    case Guidance{}:
      White{}

def sign_symbol(s: Sign) -> Colour:
  match s:
    case Warning{}:
      Black{}
    case Prohibition{}:
      Black{}
    case Command{}:
      White{}
    case Guidance{}:
      White{}

# Pasal 28 ayat (1): a warning sign under temporary works turns orange.
def sign_base_temporary(s: Sign) -> Colour:
  match s:
    case Warning{}:
      Orange{}
    case Prohibition{}:
      White{}
    case Command{}:
      Blue{}
    case Guidance{}:
      Green{}

# Pasal 13 ayat (2): the end-of-prohibition sign is the exception: black border.
def sign_border_end_of_ban() -> Colour:
  Black{}

def signs() -> List<Sign>:
  [ Warning{}, Prohibition{}, Command{}, Guidance{} ]

# ---------------------------------------------------------------------------
# What a sign requires of the driver, PM 13/2014 Tabel I to IV
#
# A warning sign names a hazard and a guidance sign gives information, so both
# carry NoDuty. A prohibition or command sign posts one of the duties below.
# The duty is the operative rule: the adjudicator charges a driver who breaks
# it, and the catalogue says which sign posted it.
# ---------------------------------------------------------------------------

# The road user a restriction names. Any covers a ban on every vehicle.
type Subject is Data:
  Any{}
  Motorcycle{}
  Car{}
  Truck{}
  Bus{}
  Public{}
  Special{}
  Trailer{}
  ThreeWheel{}
  Bicycle{}
  Pedestrian{}
  Cart{}
  Becak{}
  Pedati{}
  Delman{}
  HorseRider{}
  NonMotorized{}

type Duty is Data:
  NoDuty{}
  Stop{}
  GiveWay{}
  NoEntry{subjects: List<&2, Subject>}
  NoStopping{}
  NoParking{}
  NoLeftTurn{}
  NoRightTurn{}
  NoUTurn{}
  NoUTurnOrRight{}
  NoOvertaking{}
  NoCloseFollowing{metres: U32}
  MaxSpeed{limit: U32}
  MinSpeed{limit: U32}
  KeepLeft{}
  KeepRight{}
  TurnLeft{}
  TurnRight{}
  GoStraight{}
  ChoosePath{}
  Roundabout{}
  UseLane{subject: Subject}
  UseChains{}
  WeightLimit{limit: U32}
  AxleLimit{limit: U32}
  LengthLimit{limit: U32}
  HeightLimit{limit: U32}
  WidthLimit{limit: U32}
  DimensionLimit{width: U32, length: U32, height: U32, axle: U32}
  EndOfRestriction{}

# ---------------------------------------------------------------------------
# Driving licences, Perpol 5/2021 Pasal 3 ayat (2), 4, 8
# ---------------------------------------------------------------------------

type Sim is Data:
  A{}
  AGeneral{}
  BI{}
  BIGeneral{}
  BII{}
  BIIGeneral{}
  C{}
  CI{}
  CII{}
  D{}
  DI{}
  International{}

# Pasal 8. Zero means the regulation sets no age for the class.
def min_age(s: Sim) -> U32:
  match s:
    case A{}:
      17
    case AGeneral{}:
      20
    case BI{}:
      20
    case BIGeneral{}:
      22
    case BII{}:
      21
    case BIIGeneral{}:
      23
    case C{}:
      17
    case CI{}:
      18
    case CII{}:
      19
    case D{}:
      17
    case DI{}:
      17
    case International{}:
      0

# Pasal 4 ayat (1) and (2), in months.
def sim_validity_months(s: Sim) -> U32:
  match s:
    case International{}:
      36
    case A{}:
      60
    case AGeneral{}:
      60
    case BI{}:
      60
    case BIGeneral{}:
      60
    case BII{}:
      60
    case BIIGeneral{}:
      60
    case C{}:
      60
    case CI{}:
      60
    case CII{}:
      60
    case D{}:
      60
    case DI{}:
      60

# Pasal 3 ayat (2): the heaviest vehicle a car or bus licence covers.
# Zero means the class is bounded by another dimension instead.
def sim_max_weight(s: Sim) -> U32:
  match s:
    case A{}:
      3500
    case AGeneral{}:
      3500
    case BI{}:
      0
    case BIGeneral{}:
      0
    case BII{}:
      0
    case BIIGeneral{}:
      0
    case C{}:
      0
    case CI{}:
      0
    case CII{}:
      0
    case D{}:
      0
    case DI{}:
      3500
    case International{}:
      0

# The engine ceiling a motorcycle licence covers, in cubic centimetres.
def sim_max_cc(s: Sim) -> U32:
  match s:
    case C{}:
      250
    case CI{}:
      500
    case CII{}:
      0
    case A{}:
      0
    case AGeneral{}:
      0
    case BI{}:
      0
    case BIGeneral{}:
      0
    case BII{}:
      0
    case BIIGeneral{}:
      0
    case D{}:
      0
    case DI{}:
      0
    case International{}:
      0

# A ceiling of zero means the statute sets none for that dimension, so the
# class is unbounded there: a B class has no weight ceiling, CII no engine one.
def within_branch(ceiling: U32, value: U32, unbounded: Bool) -> Bool:
  match unbounded:
    case True{}:
      True{}
    case False{}:
      U32.is_le(value, ceiling)

def within(+ceiling: U32, value: U32) -> Bool:
  within_branch(ceiling, value, U32.is_zero(ceiling))

# A class covers a vehicle only within both dimensions it is bounded by.
def sim_covers_vehicle(+s: Sim, weight: U32, cc: U32) -> Bool:
  Bool.and(within(sim_max_weight(s), weight), within(sim_max_cc(s), cc))

# A general licence covers public carriage; a personal one does not.
def sim_public(s: Sim) -> Bool:
  match s:
    case A{}:
      False{}
    case AGeneral{}:
      True{}
    case BI{}:
      False{}
    case BIGeneral{}:
      True{}
    case BII{}:
      False{}
    case BIIGeneral{}:
      True{}
    case C{}:
      False{}
    case CI{}:
      False{}
    case CII{}:
      False{}
    case D{}:
      False{}
    case DI{}:
      False{}
    case International{}:
      True{}

def sims() -> List<Sim>:
  [ A{}, AGeneral{}, BI{}, BIGeneral{}, BII{}, BIIGeneral{}
  , C{}, CI{}, CII{}, D{}, DI{}, International{} ]

# ---------------------------------------------------------------------------
# The road network, PP 79/2013 Pasal 17, 19, 20
# ---------------------------------------------------------------------------

type RoadFunction is Data:
  Arteri{}
  Kolektor{}
  Lokal{}
  Lingkungan{}

type RoadClass is Data:
  ClassI{}
  ClassII{}
  ClassIII{}

# Pasal 19: the widest, longest, tallest and heaviest vehicle each class admits.
def class_max_width(c: RoadClass) -> U32:
  match c:
    case ClassI{}:
      2500
    case ClassII{}:
      2500
    case ClassIII{}:
      2100

def class_max_length(c: RoadClass) -> U32:
  match c:
    case ClassI{}:
      18000
    case ClassII{}:
      12000
    case ClassIII{}:
      9000

def class_max_height(c: RoadClass) -> U32:
  match c:
    case ClassI{}:
      4200
    case ClassII{}:
      4200
    case ClassIII{}:
      3500

# The heaviest axle load, in tonnes.
def class_max_axle(c: RoadClass) -> U32:
  match c:
    case ClassI{}:
      10
    case ClassII{}:
      8
    case ClassIII{}:
      8

def class_admits(+c: RoadClass, width: U32, length: U32, height: U32, axle: U32) -> Bool:
  Bool.and(U32.is_le(width, class_max_width(c)),
  Bool.and(U32.is_le(length, class_max_length(c)),
  Bool.and(U32.is_le(height, class_max_height(c)), U32.is_le(axle, class_max_axle(c)))))

def same_colour(a: Colour, b: Colour) -> Bool:
  match a b:
    case Yellow{} Yellow{}:
      True{}
    case Red{} Red{}:
      True{}
    case Blue{} Blue{}:
      True{}
    case Green{} Green{}:
      True{}
    case Brown{} Brown{}:
      True{}
    case Orange{} Orange{}:
      True{}
    case White{} White{}:
      True{}
    case Black{} Black{}:
      True{}
    case _ _:
      False{}


def is_international(s: Sim) -> Bool:
  match s:
    case International{}:
      True{}
    case _:
      False{}

def not_international(s: Sim, international: Bool) -> U32:
  match international:
    case True{}:
      0
    case False{}:
      Bool.to_u32(U32.is_zero(min_age(s)))

# One when a national class has no age floor, which would be a gap in Pasal 8.
def age_gap(+s: Sim) -> U32:
  not_international(s, is_international(s))

def no_age_go(ss: List<Sim>, bad: Nat) -> Nat:
  match ss:
    case Nil{}:
      bad
    case h <> t:
      no_age_go(t, Nat.add(bad, U32.to_nat(age_gap(h))))

# Every class except the international one carries an age floor.
def no_age_classes() -> Bool:
  Nat.is_eq(no_age_go(sims(), 0n), 0n)

def count_inst(xs: List<Inst>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_inst(t))

def count_sign(xs: List<Sign>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_sign(t))

def count_ground(xs: List<Ground>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_ground(t))

def instrument_count() -> U32:
  count_inst(instruments())

def sign_count() -> U32:
  count_sign(signs())

def grounds() -> List<Ground>:
  [ Accidents{}, Surface{}, Geometry{}, Community{} ]

def ground_count() -> U32:
  count_ground(grounds())
