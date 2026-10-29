# lajur — Perpol 5/2021: who may hold which licence, for how long, and what
# they must pass to get it.
import Base
import ./model.bend as M

# Pasal 7: four requirements, all of them, for every class.
type Requirement is Data:
  Age{}
  Administration{}
  Health{}
  Test{}

def requirements() -> List<Requirement>:
  [ Age{}, Administration{}, Health{}, Test{} ]

# Pasal 10: health is physical and psychological.
type HealthCheck is Data:
  Physical{}
  Psychological{}

def health_checks() -> List<HealthCheck>:
  [ Physical{}, Psychological{} ]

# Pasal 11 ayat (1) and 12 ayat (1): three parts each.
def physical_parts() -> U32:
  3

def psychological_parts() -> U32:
  3

# How long each certificate stays usable, in days.
def doctor_letter_days() -> U32:
  14

def psych_letter_months() -> U32:
  6

# Pasal 13: theory, simulator, practice, in that order.
def test_stages() -> U32:
  3

# Pasal 15 ayat (1), 17 ayat (1): the pass mark.
def pass_mark() -> U32:
  70

# Pasal 15 ayat (2), 17 ayat (2), 19 ayat (4): two retakes within 14 working
# days, counted from the day after the failure.
def retakes() -> U32:
  2

def retake_window_days() -> U32:
  14

# Pasal 14 ayat (5): the theory paper is in Indonesian, or English for a
# foreign applicant.
def theory_languages() -> U32:
  2

# Pasal 3 ayat (3) to (9): upgrading a class needs twelve months in the class
# below it.
def upgrade_holding_months() -> U32:
  12

# Pasal 20 ayat (1): issuing a national licence runs five steps.
def issue_steps() -> U32:
  5

# Pasal 21 ayat (1): the signature is electronic, by the Korlantas chief or a
# delegated officer.
def international_needs_national_licence() -> Bool:
  True{}


def count_requirements(xs: List<Requirement>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_requirements(t))

def count_health(xs: List<HealthCheck>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_health(t))

def requirements_count() -> U32:
  count_requirements(requirements())

def health_check_count() -> U32:
  count_health(health_checks())

# Pasal 37 ayat (2), 38 ayat (1) and 39 ayat (1): points add up, and at 12 the
# licence is held before trial; at 18 a court may revoke it.
def held_at_points() -> U32:
  12

def revoked_at_points() -> U32:
  18
