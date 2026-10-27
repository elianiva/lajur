import * as THREE from "three";
import { bengkel, house, kos, minimarket, petak, ruko, warung } from "../../assets/buildings.ts";
import { bambu, banana, flamboyan, kamboja, mangga, palm, pepaya } from "../../assets/trees.ts";
import { type Kind, BANK, riverX } from "./site.ts";

// --- placement ------------------------------------------------------------------

export interface Rect {
  x0: number;
  x1: number;
  z0: number;
  z1: number;
}

/** The yaw that points a model's local +x (a building's front) along (fx, fz). */
export function front(fx: number, fz: number): number {
  return Math.atan2(-fz, fx);
}

/** The yaw that points a model's local -z (a vehicle's nose) along (tx, tz). */
export function nose(tx: number, tz: number): number {
  return Math.atan2(-tx, -tz);
}

export function overlaps(a: Rect, b: Rect): boolean {
  return a.x0 < b.x1 && a.x1 > b.x0 && a.z0 < b.z1 && a.z1 > b.z0;
}

export function wet(rect: Rect, margin = 0): boolean {
  for (const z of [rect.z0, (rect.z0 + rect.z1) / 2, rect.z1]) {
    const river = riverX(z);
    if (rect.x1 > river - BANK - margin && rect.x0 < river + BANK + margin) return true;
  }
  return false;
}

export interface Built {
  object: THREE.Object3D;
  /** Pavement life in front of it: parked bikes, a cart, a customer. */
  busy: number;
}

export type Pick = (roll: () => number, depth: number) => Built;

export const shop = (object: THREE.Object3D, busy: number): Built => ({ object, busy });

/** What lines each kind of frontage, by weight. */
export const FRONTAGE: Record<Kind | "gang", [number, Pick][]> = {
  raya: [
    [
      6,
      (roll, depth) =>
        shop(ruko(roll() * 0.3 + 0.7, 5 + roll() * 2, Math.min(depth - 1.8, 12)), 0.9),
    ],
    [1.2, (roll) => shop(minimarket(roll()), 1)],
    [1, (roll) => shop(warung(roll(), 4, 5), 1)],
    [0.8, (roll) => shop(bengkel(roll()), 0.6)],
    [0.6, (roll, depth) => shop(house(roll(), 8 + roll() * 3, depth - 1), 0.2)],
  ],
  jalan: [
    [4, (roll, depth) => shop(ruko(roll(), 4.5 + roll() * 2, Math.min(depth - 1.8, 11)), 0.8)],
    [2, (roll) => shop(warung(roll(), 4, 5), 1)],
    [3, (roll, depth) => shop(house(roll(), 7 + roll() * 4, depth - 0.8), 0.25)],
    [1, (roll, depth) => shop(kos(roll(), 12, Math.min(depth - 1, 10)), 0.4)],
    [0.5, (roll) => shop(minimarket(roll()), 1)],
    [0.5, (roll) => shop(bengkel(roll()), 0.6)],
  ],
  lokal: [
    [4, (roll, depth) => shop(house(roll(), 6.5 + roll() * 4, depth - 0.6), 0.3)],
    [2, (roll) => shop(warung(roll(), 4, 5), 1)],
    [1.5, (roll, depth) => shop(kos(roll(), 12, Math.min(depth - 1, 10)), 0.4)],
    [1.2, (roll, depth) => shop(petak(roll(), 13.6, Math.min(depth - 1, 8)), 0.3)],
    [1.2, (roll, depth) => shop(ruko(roll(), 4.5 + roll() * 2, Math.min(depth - 1.8, 9)), 0.7)],
  ],
  gang: [
    [5, (roll, depth) => shop(house(roll(), 6 + roll() * 3.5, depth - 0.5), 0.2)],
    [2.6, (roll, depth) => shop(petak(roll(), 13.6, Math.min(depth - 1, 8)), 0.25)],
    [0.8, (roll, depth) => shop(kos(roll(), 12, Math.min(depth - 1, 10)), 0.3)],
    [0.6, (roll) => shop(warung(roll(), 4, 5), 0.8)],
  ],
};

export function choose<T>(roll: () => number, table: [number, T][]): T {
  const total = table.reduce((sum, [weight]) => sum + weight, 0);
  let at = roll() * total;
  for (const [weight, value] of table) {
    at -= weight;
    if (at <= 0) return value;
  }
  return table[table.length - 1]![1];
}

export const STREET_TREES = [palm, mangga, kamboja, flamboyan, pepaya, banana];
export const BANK_TREES = [palm, bambu, banana, mangga, palm];
