# lajur — PP 37/2017: the safety plans, the five pillars, and the safety
# management system a public transport company must run.
import Base

# Pasal 4 ayat (1): the five pillars of the national road safety programme.
type Pillar is Data:
  System{}
  Road{}
  Vehicle{}
  User{}
  Care{}

def pillars() -> List<Pillar>:
  [ System{}, Road{}, Vehicle{}, User{}, Care{} ]

# Pasal 3 ayat (2) and 6 ayat (2): a national plan runs twenty years.
def plan_years() -> U32:
  20

# Pasal 6 ayat (3): it is evaluated every five years.
def plan_review_years() -> U32:
  5

# Pasal 9 ayat (4) and 10 ayat (4): a ministry or regional action plan runs five
# years and is reviewed every year.
def action_plan_years() -> U32:
  5

def action_plan_review_years() -> U32:
  1

# Pasal 12 ayat (4): implementation is evaluated every three months.
def implementation_review_months() -> U32:
  3

# Pasal 16 ayat (1): the ten elements of a company safety management system.
type Element is Data:
  Commitment{}
  Organisation{}
  Hazard{}
  Facility{}
  Documentation{}
  Competence{}
  Emergency{}
  Reporting{}
  Monitoring{}
  Performance{}

def elements() -> List<Element>:
  [ Commitment{}, Organisation{}, Hazard{}, Facility{}, Documentation{}
  , Competence{}, Emergency{}, Reporting{}, Monitoring{}, Performance{} ]

# Pasal 28 ayat (1): the system is in place within three months of the permit.
def system_deadline_months() -> U32:
  3

# Pasal 25: monitoring and review run every three months.
def review_interval_months() -> U32:
  3

# Pasal 26 ayat (1): two ratios measure safety, accidents per vehicle kilometre
# and victims per accident.
def performance_ratios() -> U32:
  2

# Pasal 14 ayat (1) to (5): five kinds of direct action carry the plan.
type Action is Data:
  RoadFitness{}
  VehicleSafety{}
  DriverCompetence{}
  Enforcement{}
  VictimCare{}

def direct_actions() -> List<Action>:
  [ RoadFitness{}, VehicleSafety{}, DriverCompetence{}, Enforcement{}, VictimCare{} ]


def count_pillar(xs: List<Pillar>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_pillar(t))

def count_element(xs: List<Element>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_element(t))

def count_action(xs: List<Action>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_action(t))

def pillar_count() -> U32:
  count_pillar(pillars())

def element_count() -> U32:
  count_element(elements())

def action_count() -> U32:
  count_action(direct_actions())
