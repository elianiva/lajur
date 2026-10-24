# lajur — what UU 22/2009 says about the vehicle itself: type test,
# registration, periodic test, equipment.
import Base

type Vehicle is Data:
  Motorcycle{}
  PassengerCar{}
  Bus{}
  GoodsVehicle{}
  Trailer{}

# Pasal 53 ayat (1): the periodic test is for vehicles that carry the public or
# carry goods. A private car and a motorcycle are not on the list.
def needs_periodic_test(v: Vehicle) -> Bool:
  match v:
    case Motorcycle{}:
      False{}
    case PassengerCar{}:
      False{}
    case Bus{}:
      True{}
    case GoodsVehicle{}:
      True{}
    case Trailer{}:
      True{}

# Pasal 53 ayat (1) also covers a public passenger car, which is a PassengerCar
# carrying fare-paying passengers rather than the same body type in private use.
def needs_periodic_test_when_public(v: Vehicle, public: Bool) -> Bool:
  match v:
    case PassengerCar{}:
      public
    case _:
      needs_periodic_test(v)

# Pasal 49 and 51: a vehicle passes a type test before it is registered, and a
# modification that changes construction or material forces a new one.
def type_test_before_registration() -> Bool:
  True{}
type Kit is Data:
  SpareTyre{}
  Triangle{}
  Jack{}
  WheelSpanner{}
  FirstAid{}

def four_wheel_kit() -> List<Kit>:
  [ SpareTyre{}, Triangle{}, Jack{}, WheelSpanner{}, FirstAid{} ]

# Pasal 57 ayat (2): a motorcycle's kit is a helmet to the national standard.
def motorcycle_kit_is_helmet() -> Bool:
  True{}

# Pasal 285: the technical items a vehicle must have to be roadworthy.
type Item is Data:
  Mirror{}
  Horn{}
  Headlamp{}
  ReverseLamp{}
  DimensionLamp{}
  TrailerLamp{}
  BrakeLamp{}
  DirectionLamp{}
  Reflector{}
  Speedometer{}
  TreadDepth{}
  Windscreen{}
  Mudguard{}
  Bumper{}
  Coupling{}
  Attachment{}
  Wiper{}
  Muffler{}

# Pasal 285 ayat (1): nine items for a motorcycle.
def motorcycle_items() -> List<Item>:
  [ Mirror{}, Horn{}, Headlamp{}, BrakeLamp{}, DirectionLamp{}
  , Reflector{}, Speedometer{}, Muffler{}, TreadDepth{} ]

# Pasal 285 ayat (2): seventeen items for a vehicle of four wheels or more.
def four_wheel_items() -> List<Item>:
  [ Mirror{}, Horn{}, Headlamp{}, ReverseLamp{}, DimensionLamp{}, TrailerLamp{}
  , BrakeLamp{}, DirectionLamp{}, Reflector{}, Speedometer{}, TreadDepth{}
  , Windscreen{}, Mudguard{}, Bumper{}, Coupling{}, Attachment{}, Wiper{} ]

# Pasal 58: an accessory that disturbs safety is forbidden, however useful.
def accessory_allowed(disturbs_safety: Bool) -> Bool:
  Bool.not(disturbs_safety)

# Pasal 68: registration issues two things, a certificate and a plate.
def registration_documents() -> U32:
  2

# A plate carries the region code, the registration number and the expiry date.
def plate_fields() -> U32:
  3


def count_kit(xs: List<Kit>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_kit(t))

def count_item(xs: List<Item>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_item(t))

def kit_count() -> U32:
  count_kit(four_wheel_kit())

def bike_item_count() -> U32:
  count_item(motorcycle_items())

def car_item_count() -> U32:
  count_item(four_wheel_items())
