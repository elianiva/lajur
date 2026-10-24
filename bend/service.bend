# lajur — PP 30/2021: traffic impact analysis, terminals, and the papers an
# operator must carry. The rest of the regulation governs permits; this module
# keeps the parts that bind a road user or an operator.
import Base

# Pasal 2 and 3: three kinds of development trigger a traffic impact analysis.
type Development is Data:
  ActivityCentre{}
  Settlement{}
  Infrastructure{}

def developments() -> List<Development>:
  [ ActivityCentre{}, Settlement{}, Infrastructure{} ]

# Pasal 7: approval comes from the authority that owns the road.
type Authority is Data:
  Minister{}
  Governor{}
  Regent{}

def approval_authority(road_is_national: Bool, road_is_provincial: Bool) -> Authority:
  match road_is_national:
    case True{}:
      Minister{}
    case False{}:
      match road_is_provincial:
        case True{}:
          Governor{}
        case False{}:
          Regent{}

# Pasal 5: the developer pays for the analysis, and the scale of the trip
# generation decides whether a full document is required.
def analysis_is_developer_duty() -> Bool:
  True{}

def needs_full_document(high_impact: Bool) -> Bool:
  high_impact

# Pasal 15: a written warning is issued three times, thirty calendar days each,
# before the next administrative sanction.
def warnings() -> U32:
  3

def warning_days() -> U32:
  30

# Pasal 41: a terminal is trialled and socialised at least one month before it
# is declared open.
def terminal_trial_months() -> U32:
  1

# UU 22/2009 Pasal 166: the papers a public transport operator carries.
type Paper is Data:
  Ticket{}
  BaggageTag{}
  Manifest{}
  CarriageAgreement{}

def passenger_papers() -> List<Paper>:
  [ Ticket{}, BaggageTag{}, Manifest{} ]

def goods_papers() -> List<Paper>:
  [ CarriageAgreement{}, Manifest{} ]

# UU 22/2009 Pasal 36: a route operator calls at the terminal named in the
# permit unless the permit says otherwise.
def terminal_on_route(permit_excuses: Bool) -> Bool:
  Bool.not(permit_excuses)

# UU 22/2009 Pasal 189 and 237: insurance covers passengers, goods, third
# parties, and the crew.
def insurance_cover_count() -> U32:
  4

def same_authority(a: Authority, b: Authority) -> Bool:
  match a b:
    case Minister{} Minister{}:
      True{}
    case Governor{} Governor{}:
      True{}
    case Regent{} Regent{}:
      True{}
    case _ _:
      False{}


def count_development(xs: List<Development>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_development(t))

def count_paper(xs: List<Paper>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_paper(t))

def development_count() -> U32:
  count_development(developments())

def passenger_paper_count() -> U32:
  count_paper(passenger_papers())

def goods_paper_count() -> U32:
  count_paper(goods_papers())
