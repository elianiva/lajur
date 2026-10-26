// The compiled parcels model (logic/parcels.bend), as the lab reads it.
// Positions are metres from the cell's first corner; the corner, (ox, oz), is
// in signed centimetres. Uses, court uses and species are codes: see the
// model for their order.

export type List<T> = { $: "Con"; head: T; tail: List<T> } | { $: "Nil" };
export type V = { $: "V"; x: number; z: number };

declare const parcels: {
  parcels_of(
    seed: number,
    i: number,
    j: number,
  ): {
    $: "Plan";
    ox: number;
    oz: number;
    lots: List<{ $: "Lot"; use: number; pts: List<V> }>;
    courts: List<{ $: "Court"; use: number; yard: boolean; pts: List<V> }>;
    trees: List<{ $: "Tree"; x: number; z: number; r: number; sp: number }>;
  };
};

export default parcels;
