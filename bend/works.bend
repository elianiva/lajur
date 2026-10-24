# lajur — UU 28/2014: what carries copyright, for how long, and why this
# repository may store the statutes at all.
import Base

# Pasal 42: five kinds of work carry no copyright. A statute is the second.
type Exempt is Data:
  PublicMeeting{}
  Statute{}
  StateSpeech{}
  CourtRuling{}
  Scripture{}

def exempt_works() -> List<Exempt>:
  [ PublicMeeting{}, Statute{}, StateSpeech{}, CourtRuling{}, Scripture{} ]

def statute_is_exempt() -> Bool:
  True{}

# Pasal 58 ayat (2) to (3), 59 ayat (2), 60 ayat (1) to (3): how long protection
# lasts, in years. Zero means no limit.
def term_after_author_dies() -> U32:
  70

def term_for_legal_entity() -> U32:
  50

def term_for_applied_art() -> U32:
  25

def term_for_unknown_author() -> U32:
  50

def term_for_traditional_culture() -> U32:
  0

# The longest term is the author's life plus seventy years, so a work is free
# at least seventy years after the last author dies.
def longest_term() -> U32:
  70


def count_exempt(xs: List<Exempt>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_exempt(t))

def exempt_count() -> U32:
  count_exempt(exempt_works())
