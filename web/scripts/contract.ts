// Checks that every function a hand-written src/<name>.d.mts declares is one
// the compiled src/<name>.mjs exports. A function renamed or dropped in a Bend
// module otherwise reaches the page as `undefined` at run time, because the
// types only say what the model should export. The reverse is not checked: the
// module exports every function it imports, and the types name the few in use.
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { buildLogic, MODULES } from "./bend.ts";

const built = buildLogic();
if (!built.ok) {
  console.error(built.output);
  process.exit(1);
}

let failed = false;
for (const name of MODULES) {
  const text = readFileSync(`src/${name}.d.mts`, "utf8");
  // The members are the two-space-indented names in the block that declares
  // the module's object: `interface Game {` or `declare const world: {`.
  const block =
    /^(?:export )?(?:interface \w+|declare const \w+: ?)\s*\{\n([\s\S]*?)^\}/m.exec(text)?.[1] ??
    "";
  const declared = new Set([...block.matchAll(/^ {2}(\w+)\??[(:]/gm)].map((match) => match[1]!));
  const module = await import(pathToFileURL(`src/${name}.mjs`).href);
  const exported = new Set(Object.keys(module.default));
  const stale = [...declared].filter((key) => !exported.has(key));
  if (stale.length > 0)
    console.error(`${name}.d.mts declares what ${name}.mjs lacks: ${stale.join(", ")}`);
  failed ||= stale.length > 0;
  if (declared.size === 0) {
    console.error(`${name}.d.mts: no members found`);
    failed = true;
  }
}
if (failed) process.exit(1);
console.log(`${MODULES.length} modules match their types`);
