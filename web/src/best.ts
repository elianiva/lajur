/**
 * Which street a shift drives and the best fares on it. A day's street is the
 * same for everyone that day: its seed is the date. The model makes the rest
 * of the world from the seed.
 */

/** Today's date as a seed: 20261029 for 29 October 2026. */
export function today(now = new Date()): number {
  return now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
}

/** Any street, kept apart from the daily ones. */
export function anyStreet(): number {
  return 100_000_000 + Math.floor(Math.random() * 900_000_000);
}

export function isDaily(seed: number): boolean {
  return seed < 100_000_000;
}

const key = (seed: number) => (isDaily(seed) ? `lajur.best.${seed}` : "lajur.best.any");

export function best(seed: number): number {
  return Number(localStorage.getItem(key(seed)) ?? 0);
}

/** Keeps `earned` if it beats the best for the street; answers whether it did. */
export function record(seed: number, earned: number): boolean {
  if (earned <= best(seed)) return false;
  localStorage.setItem(key(seed), String(earned));
  return true;
}
