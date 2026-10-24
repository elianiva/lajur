# lajur — a machine-checked model of Indonesian traffic rules (v0 slice).
#
# Each rule in the catalogue names its instrument and article. The adjudicator
# returns rule ids only, so the catalogue is the single source of truth for
# citation and sanction. LAWS.bend states properties of this file; PROOF.bend
# proves them.
import Base

type Zone is Data:
  Residential{}
  Urban{}
  Intercity{}
  Motorway{}

type Vehicle is Data:
  Motorcycle{}
  Car{}
  Truck{}
  Bus{}

type Side is Data:
  Left{}
  Right{}

type Grade is Data:
  Flat{}
  Uphill{}
  Downhill{}

# An officer's direction outranks a signal, a signal a sign, a sign a marking,
# and a marking the general rule.
type Tier is Data:
  Officer{}
  Signal{}
  Sign{}
  Marking{}
  General{}

type Rule is Data:
  Rule{id: U32, tier: Tier, months: U32, fine: U32, instrument: String, article: String}

type Road is Data:
  Road{zone: Zone, lane: Side, police_directs: Bool, signal_red: Bool, sign_forbids: Bool, marking_forbids: Bool}

type Payload is Data:
  Payload{vehicle: Vehicle, passengers: Nat, sidecar: Bool}

type Equipment is Data:
  Equipment{rider_helmet: Bool, passenger_helmet: Bool, seatbelt: Bool, night: Bool, lights_on: Bool, phone: Bool}

type Motion is Data:
  Motion{speed: U32, overtaking: Bool, overtake_side: Side, front_signals_right: Bool, turning: Bool, indicates_turn: Bool}

type Priority is Data:
  Priority{oncoming: Bool, oncoming_room: Bool, grade: Grade, yields_to_uphill: Bool, pedestrian_waiting: Bool, yields_to_pedestrian: Bool}

type Papers is Data:
  Papers{sim: Bool, stnk: Bool}

type Scenario is Data:
  Scenario{road: Road, load: Payload, gear: Equipment, move: Motion, yield: Priority, docs: Papers}

# ---------------------------------------------------------------------------
# Rule catalogue
# ---------------------------------------------------------------------------

def catalogue() -> List<Rule>:
  [ Rule{1, General{}, 0, 0, "UU 22/2009", "Pasal 108 ayat (1) dan (2)"}
  , Rule{2, General{}, 0, 0, "UU 22/2009", "Pasal 109 ayat (1)"}
  , Rule{3, General{}, 0, 0, "UU 22/2009", "Pasal 109 ayat (3)"}
  , Rule{4, General{}, 0, 0, "UU 22/2009", "Pasal 110 ayat (1)"}
  , Rule{5, General{}, 0, 0, "UU 22/2009", "Pasal 111"}
  , Rule{6, General{}, 1, 250000, "UU 22/2009", "Pasal 112 ayat (1), sanksi Pasal 294"}
  , Rule{7, General{}, 1, 250000, "UU 22/2009", "Pasal 106 ayat (8), sanksi Pasal 291 ayat (1)"}
  , Rule{8, General{}, 1, 250000, "UU 22/2009", "Pasal 106 ayat (8), sanksi Pasal 291 ayat (2)"}
  , Rule{9, General{}, 1, 250000, "UU 22/2009", "Pasal 106 ayat (9), sanksi Pasal 292"}
  , Rule{10, General{}, 1, 250000, "UU 22/2009", "Pasal 106 ayat (6), sanksi Pasal 289"}
  , Rule{11, General{}, 3, 750000, "UU 22/2009", "Pasal 106 ayat (1), sanksi Pasal 283"}
  , Rule{12, General{}, 2, 500000, "UU 22/2009", "Pasal 106 ayat (2), sanksi Pasal 284"}
  , Rule{13, Signal{}, 2, 500000, "UU 22/2009", "Pasal 106 ayat (4) huruf c, sanksi Pasal 287 ayat (2)"}
  , Rule{14, Sign{}, 2, 500000, "UU 22/2009", "Pasal 106 ayat (4) huruf a, sanksi Pasal 287 ayat (1)"}
  , Rule{15, Marking{}, 2, 500000, "UU 22/2009", "Pasal 106 ayat (4) huruf b, sanksi Pasal 287 ayat (1)"}
  , Rule{16, General{}, 1, 250000, "UU 22/2009", "Pasal 107, sanksi Pasal 293"}
  , Rule{17, Sign{}, 2, 500000, "UU 22/2009", "Pasal 21, sanksi Pasal 287 ayat (5); PM 111/2015"}
  , Rule{18, General{}, 1, 250000, "UU 22/2009", "Pasal 106 ayat (5) huruf b, sanksi Pasal 288 ayat (2)"}
  , Rule{19, General{}, 2, 500000, "UU 22/2009", "Pasal 106 ayat (5) huruf a, sanksi Pasal 288 ayat (1)"}
  ]

def Rule.sanction_is(r: Rule, id: U32, months: U32, fine: U32) -> Bool:
  match r:
    case Rule{+rid, tier, +rmonths, +rfine, instrument, article}:
      Bool.and(U32.is_eq(rid, id), Bool.and(U32.is_eq(rmonths, months), U32.is_eq(rfine, fine)))

def sanction_matches(+id: U32, +months: U32, +fine: U32, rs: List<Rule>) -> Bool:
  match rs:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(Rule.sanction_is(h, id, months, fine), sanction_matches(id, months, fine, t))

# The sanctions the statute states outright, checked against the catalogue.
def sanctions_ok() -> Bool:
  Bool.and(sanction_matches(6, 1, 250000, catalogue()),
  Bool.and(sanction_matches(7, 1, 250000, catalogue()),
  Bool.and(sanction_matches(8, 1, 250000, catalogue()),
  Bool.and(sanction_matches(9, 1, 250000, catalogue()),
  Bool.and(sanction_matches(10, 1, 250000, catalogue()),
  Bool.and(sanction_matches(11, 3, 750000, catalogue()),
  Bool.and(sanction_matches(12, 2, 500000, catalogue()),
  Bool.and(sanction_matches(13, 2, 500000, catalogue()),
  Bool.and(sanction_matches(14, 2, 500000, catalogue()),
  Bool.and(sanction_matches(15, 2, 500000, catalogue()),
  Bool.and(sanction_matches(16, 1, 250000, catalogue()),
  Bool.and(sanction_matches(17, 2, 500000, catalogue()),
  Bool.and(sanction_matches(18, 1, 250000, catalogue()),
           sanction_matches(19, 2, 500000, catalogue()))))))))))))))

def tier_code(t: Tier) -> U32:
  match t:
    case Officer{}:
      0
    case Signal{}:
      1
    case Sign{}:
      2
    case Marking{}:
      3
    case General{}:
      4

def Rule.tier_of(r: Rule, id: U32) -> U32:
  match r:
    case Rule{+rid, +tier, months, fine, instrument, article}:
      Bool.pick(U32, U32.is_eq(rid, id), tier_code(tier), 99)

def tier_of(+id: U32, rs: List<Rule>) -> U32:
  match rs:
    case Nil{}:
      99
    case h <> t:
      +n = Rule.tier_of(h, id)
      Bool.pick(U32, U32.is_eq(n, 99), tier_of(id, t), n)

# The catalogue uses the precedence tiers where the articles demand them:
# a signal rule over a sign rule over a marking rule.
def tiers_ok() -> Bool:
  Bool.and(U32.is_eq(tier_of(13, catalogue()), 1),
  Bool.and(U32.is_eq(tier_of(14, catalogue()), 2),
  Bool.and(U32.is_eq(tier_of(15, catalogue()), 3),
  Bool.and(U32.is_eq(tier_of(17, catalogue()), 2),
           U32.is_eq(tier_of(1, catalogue()), 4)))))

def catalogue_count() -> Nat:
  List.length(&1, Rule, catalogue)

def Rule.article_ok(r: Rule) -> Bool:
  match r:
    case Rule{id, tier, months, fine, instrument, article}:
      Bool.and(Bool.not(String.is_empty(instrument)), Bool.not(String.is_empty(article)))

def Rule.id_is(r: Rule, id: U32) -> Bool:
  match r:
    case Rule{+rid, tier, months, fine, instrument, article}:
      U32.is_eq(rid, id)

def catalogue_citations_ok(rs: List<Rule>) -> Bool:
  match rs:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(Rule.article_ok(h), catalogue_citations_ok(t))

def catalogue_has(+id: U32, rs: List<Rule>) -> Bool:
  match rs:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(Rule.id_is(h, id), catalogue_has(id, t))

def charged_ids_catalogued(ids: List<U32>) -> Bool:
  match ids:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(catalogue_has(h, catalogue()), charged_ids_catalogued(t))


# ---------------------------------------------------------------------------
# Predicates over a scenario
# ---------------------------------------------------------------------------

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

def speed_limits_ok() -> Bool:
  Bool.and(U32.is_eq(speed_limit(Residential{}), 30),
  Bool.and(U32.is_eq(speed_limit(Urban{}), 50),
  Bool.and(U32.is_eq(speed_limit(Intercity{}), 80),
           U32.is_eq(speed_limit(Motorway{}), 100))))

def is_motorcycle(v: Vehicle) -> Bool:
  match v:
    case Motorcycle{}:
      True{}
    case Car{}:
      False{}
    case Truck{}:
      False{}
    case Bus{}:
      False{}

def lane_is_right(s: Side) -> Bool:
  match s:
    case Left{}:
      False{}
    case Right{}:
      True{}

def grade_is_downhill(g: Grade) -> Bool:
  match g:
    case Flat{}:
      False{}
    case Uphill{}:
      False{}
    case Downhill{}:
      True{}

def push(cond: Bool, id: U32, rest: List<U32>) -> List<U32>:
  match cond:
    case True{}:
      id <> rest
    case False{}:
      rest

# Rule ids in ascending order, one per violation found.
def charges(s: Scenario) -> List<U32>:
  match s:
    case Scenario{road, load, gear, move, yield, docs}:
      Road{+zone, +lane, +police_directs, +signal_red, +sign_forbids, +marking_forbids} = road
      Payload{+vehicle, +passengers, +sidecar} = load
      Equipment{+rider_helmet, +passenger_helmet, +seatbelt, +night, +lights_on, +phone} = gear
      Motion{+speed, +overtaking, +overtake_side, +front_signals_right, +turning, +indicates_turn} = move
      Priority{+oncoming, +oncoming_room, +grade, +yields_to_uphill, +pedestrian_waiting, +yields_to_pedestrian} = yield
      Papers{+sim, +stnk} = docs
      +bike = is_motorcycle(vehicle)
      push(Bool.and(lane_is_right(lane), Bool.and(Bool.not(overtaking), Bool.not(police_directs))), 1,
      push(Bool.and(overtaking, Bool.not(lane_is_right(overtake_side))), 2,
      push(Bool.and(overtaking, front_signals_right), 3,
      push(Bool.and(oncoming, Bool.not(oncoming_room)), 4,
      push(Bool.and(grade_is_downhill(grade), Bool.not(yields_to_uphill)), 5,
      push(Bool.and(turning, Bool.not(indicates_turn)), 6,
      push(Bool.and(bike, Bool.not(rider_helmet)), 7,
      push(Bool.and(bike, Bool.and(Nat.is_lt(0n, passengers), Bool.not(passenger_helmet))), 8,
      push(Bool.and(bike, Bool.and(Bool.not(sidecar), Nat.is_lt(1n, passengers))), 9,
      push(Bool.and(Bool.not(bike), Bool.not(seatbelt)), 10,
      push(phone, 11,
      push(Bool.and(pedestrian_waiting, Bool.not(yields_to_pedestrian)), 12,
      push(signal_red, 13,
      push(sign_forbids, 14,
      push(marking_forbids, 15,
      push(Bool.and(Bool.or(night, bike), Bool.not(lights_on)), 16,
      push(U32.is_lt(speed_limit(zone), speed), 17,
      push(Bool.not(sim), 18,
      push(Bool.not(stnk), 19,
           Nil{})))))))))))))))))))

def contains(+id: U32, ids: List<U32>) -> Bool:
  match ids:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(U32.is_eq(h, id), contains(id, t))

def ids_equal(a: List<U32>, b: List<U32>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case Nil{} _ <> _:
      False{}
    case _ <> _ Nil{}:
      False{}
    case ha <> ta hb <> tb:
      Bool.and(U32.is_eq(ha, hb), ids_equal(ta, tb))

# ---------------------------------------------------------------------------
# Scenarios: a small corpus with its golden verdicts
# ---------------------------------------------------------------------------

def clean_road() -> Road:
  Road{Urban{}, Left{}, False{}, False{}, False{}, False{}}

def clean_load() -> Payload:
  Payload{Car{}, 0n, False{}}

def clean_gear() -> Equipment:
  Equipment{True{}, True{}, True{}, False{}, True{}, False{}}

def clean_move() -> Motion:
  Motion{40, False{}, Right{}, False{}, False{}, True{}}

def clean_yield() -> Priority:
  Priority{False{}, True{}, Flat{}, True{}, False{}, True{}}

def clean_docs() -> Papers:
  Papers{True{}, True{}}

def clean_car() -> Scenario:
  Scenario{clean_road(), clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs()}

def bike_no_helmet() -> Scenario:
  Scenario{
    clean_road(),
    Payload{Motorcycle{}, 0n, False{}},
    Equipment{False{}, True{}, True{}, False{}, True{}, False{}},
    clean_move(), clean_yield(), clean_docs()}

def bike_two_passengers() -> Scenario:
  Scenario{
    clean_road(),
    Payload{Motorcycle{}, 2n, False{}},
    Equipment{True{}, False{}, True{}, False{}, True{}, False{}},
    clean_move(), clean_yield(), clean_docs()}

def car_red_light_phone() -> Scenario:
  Scenario{
    Road{Urban{}, Left{}, False{}, True{}, False{}, False{}},
    clean_load(),
    Equipment{True{}, True{}, False{}, False{}, True{}, True{}},
    clean_move(), clean_yield(), clean_docs()}

def car_speeding() -> Scenario:
  Scenario{
    Road{Residential{}, Left{}, False{}, False{}, False{}, False{}},
    clean_load(), clean_gear(),
    Motion{45, False{}, Right{}, False{}, False{}, True{}},
    clean_yield(), clean_docs()}

def bike_night_downhill() -> Scenario:
  Scenario{
    clean_road(),
    Payload{Motorcycle{}, 0n, False{}},
    Equipment{True{}, True{}, True{}, True{}, False{}, False{}},
    clean_move(),
    Priority{False{}, True{}, Downhill{}, False{}, True{}, False{}},
    clean_docs()}

def car_right_lane() -> Scenario:
  Scenario{
    Road{Urban{}, Right{}, False{}, False{}, False{}, False{}},
    clean_load(), clean_gear(), clean_move(), clean_yield(), clean_docs()}

def car_overtake_left() -> Scenario:
  Scenario{
    clean_road(), clean_load(), clean_gear(),
    Motion{50, True{}, Left{}, True{}, False{}, True{}},
    clean_yield(), clean_docs()}

def car_turning_no_docs() -> Scenario:
  Scenario{
    clean_road(), clean_load(), clean_gear(),
    Motion{30, False{}, Right{}, False{}, True{}, False{}},
    clean_yield(),
    Papers{False{}, False{}}}

def bike_helmet(h: Bool) -> Scenario:
  Scenario{
    clean_road(),
    Payload{Motorcycle{}, 0n, False{}},
    Equipment{h, True{}, True{}, False{}, True{}, False{}},
    clean_move(), clean_yield(), clean_docs()}

def bike_passengers(p: Nat) -> Scenario:
  Scenario{
    clean_road(),
    Payload{Motorcycle{}, p, False{}},
    clean_gear(), clean_move(), clean_yield(), clean_docs()}

def Bool.same(a: Bool, b: Bool) -> Bool:
  match a b:
    case True{} True{}:
      True{}
    case False{} False{}:
      True{}
    case True{} False{}:
      False{}
    case False{} True{}:
      False{}

def vehicle_of(m: Bool) -> Vehicle:
  match m:
    case True{}:
      Motorcycle{}
    case False{}:
      Car{}

def seatbelt_case(m: Bool) -> Scenario:
  Scenario{
    clean_road(),
    Payload{vehicle_of(m), 0n, False{}},
    Equipment{True{}, True{}, False{}, False{}, True{}, False{}},
    clean_move(), clean_yield(), clean_docs()}

def passenger_counts_ok() -> Bool:
  Bool.and(Bool.same(contains(9, charges(bike_passengers(0n))), False{}),
  Bool.and(Bool.same(contains(9, charges(bike_passengers(1n))), False{}),
  Bool.and(Bool.same(contains(9, charges(bike_passengers(2n))), True{}),
           Bool.same(contains(9, charges(bike_passengers(3n))), True{}))))

type Sample is Type:
  Sample{name: String, want: List<U32>, got: List<U32>}

def Sample.catalogued(c: Sample) -> Bool:
  match c:
    case Sample{name, want, got}:
      Bool.and(charged_ids_catalogued(want), charged_ids_catalogued(got))

def Sample.catalogued_all(cs: List<Sample>) -> Bool:
  match cs:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(Sample.catalogued(h), Sample.catalogued_all(t))

def Sample.ok(c: Sample) -> Bool:
  match c:
    case Sample{name, want, got}:
      ids_equal(want, got)

def Sample.passes(cs: List<Sample>) -> Bool:
  match cs:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(Sample.ok(h), Sample.passes(t))

def corpus() -> List<Sample>:
  [ Sample{"clean car", Nil{}, charges(clean_car())}
  , Sample{"bike, no rider helmet", [7], charges(bike_no_helmet())}
  , Sample{"bike, two passengers, no passenger helmet", [8, 9], charges(bike_two_passengers())}
  , Sample{"car, red light, phone, no seatbelt", [10, 11, 13], charges(car_red_light_phone())}
  , Sample{"car, 45 in a 30 zone", [17], charges(car_speeding())}
  , Sample{"bike at night, lights off, downhill, pedestrian", [5, 12, 16], charges(bike_night_downhill())}
  , Sample{"car, right lane, not overtaking", [1], charges(car_right_lane())}
  , Sample{"car, overtaking on the left of a right-signalling car", [2, 3], charges(car_overtake_left())}
  , Sample{"car, turning without signal, no SIM, no STNK", [6, 18, 19], charges(car_turning_no_docs())}
  ]

def corpus_passes() -> Bool:
  Sample.passes(corpus())

def corpus_catalogued() -> Bool:
  Sample.catalogued_all(corpus())
