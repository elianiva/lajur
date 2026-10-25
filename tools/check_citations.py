"""Check every catalogue citation against the statute the corpus stores.

`bend/rules.bend` gives each rule the article that imposes its duty and the
article that punishes breaking it. The prover checks that both numbers are
non-zero; it cannot see whether the statute agrees. This script reads the
catalogue and `corpus/provisions.json` and asks the same question a reader
would: does the article the model says punishes the rule actually name the
article the model says imposes it, at the ayat the model states, with the
numbers the model states?

    .venv/bin/python tools/check_citations.py

Exit status is zero when every citation is found and the numbers agree.

A provision whose text lost its numeral in extraction reports as a warning,
not an error: the model states the number, the corpus cannot confirm it.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOGUE = ROOT / "bend" / "rules.bend"
CORPUS = ROOT / "corpus" / "provisions.json"
INSTRUMENT = "uu-22-2009"

RULE = re.compile(
    r"Rule\{(\d+),\s*\w+\{\},\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\}"
)


@dataclass(frozen=True)
class Rule:
    id: int
    months: int
    days: int
    fine: int
    art: int
    ay: int
    pen_art: int
    pen_ay: int


def catalogue() -> list[Rule]:
    return [Rule(*map(int, m)) for m in RULE.findall(CATALOGUE.read_text())]


def provisions() -> list[dict]:
    return json.loads(CORPUS.read_text())


def at(rows: list[dict], article: int, ayat: int | None) -> str:
    """The provision's text, or every provision of the article when ayat is None."""
    picked = [
        row["text"]
        for row in rows
        if row["instrument"] == INSTRUMENT
        and row["article"] == article
        and (ayat is None or row["ayat"] == ayat)
    ]
    return re.sub(r"\s+", " ", " ".join(picked))


def amounts(text: str) -> tuple[int | None, int | None, int]:
    """Months, days and rupiah the text states. The term is None when the
    extraction lost its numeral, which is a warning rather than a mismatch."""
    months: int | None = None
    days: int | None = None
    term = re.search(r"paling lama\s*(\d+)\s*\([^)]*\)\s*(tahun|bulan|hari)", text)
    if term:
        count, unit = int(term.group(1)), term.group(2)
        if unit == "tahun":
            months = count * 12
        elif unit == "bulan":
            months = count
        else:
            days = count
    fine = re.search(r"denda paling(?: paling)? banyak Rp([\d.]+)", text)
    return months, days, int(fine.group(1).replace(".", "")) if fine else 0


def check(rule: Rule, rows: list[dict]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    if rule.pen_art == 0:
        return errors, warnings
    penalty = at(rows, rule.pen_art, rule.pen_ay or None)
    if not penalty:
        return [f"rule {rule.id}: no provision at Pasal {rule.pen_art} ayat ({rule.pen_ay})"], warnings
    if rule.pen_art != rule.art:
        if f"Pasal {rule.art}" not in penalty:
            errors.append(
                f"rule {rule.id}: Pasal {rule.pen_art} ayat ({rule.pen_ay}) does not cite "
                f"Pasal {rule.art}, the article the rule names as its duty"
            )
        elif rule.ay:
            cited = [int(n) for n in re.findall(rf"Pasal {rule.art} ayat \((\d+)\)", penalty)]
            if cited and rule.ay not in cited:
                errors.append(
                    f"rule {rule.id}: Pasal {rule.pen_art} cites Pasal {rule.art} ayat "
                    f"{cited}, not ayat ({rule.ay})"
                )
    months, days, fine = amounts(penalty)
    if months is None and days is None:
        warnings.append(f"rule {rule.id}: Pasal {rule.pen_art} lost its term in extraction")
    elif months is not None and months != rule.months:
        errors.append(f"rule {rule.id}: states {rule.months} months, Pasal {rule.pen_art} states {months}")
    elif days is not None and days != rule.days:
        errors.append(f"rule {rule.id}: states {rule.days} days, Pasal {rule.pen_art} states {days}")
    if fine != rule.fine:
        errors.append(f"rule {rule.id}: states Rp{rule.fine}, Pasal {rule.pen_art} states Rp{fine}")
    return errors, warnings


def main() -> int:
    rows = provisions()
    rules = catalogue()
    errors: list[str] = []
    warnings: list[str] = []
    for rule in rules:
        bad, unsure = check(rule, rows)
        errors += bad
        warnings += unsure
    for line in warnings:
        print(f"warning: {line}")
    for line in errors:
        print(f"error: {line}")
    print(f"{len(rules)} rules, {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
