// Finds the Bend toolchain the same way for `vp dev`, `vp build` and the
// `logic` / `proof` scripts, and reports clearly when it is missing.
import { execFileSync } from "node:child_process";
import { homedir } from "node:os";
import { pathToFileURL } from "node:url";

const BEND_DIR = "logic";

function candidates(): string[] {
  const home = homedir();
  return [process.env.BEND, `${home}/.bend/bin/bend`, "bend"].filter((entry): entry is string =>
    Boolean(entry),
  );
}

export function findBend(): string {
  for (const candidate of candidates()) {
    try {
      execFileSync(candidate, ["version"], { stdio: "ignore" });
      return candidate;
    } catch {
      // try the next one
    }
  }
  throw new Error(
    "Bend is not installed. The game logic is a Bend program: install the toolchain with\n" +
      "  curl -fsSL https://bend-lang.com/install.sh | sh\n" +
      "or point BEND at the binary.",
  );
}

export function runBend(args: string[]): void {
  execFileSync(findBend(), args, { stdio: "inherit" });
}

export interface Built {
  ok: boolean;
  output: string;
}

/**
 * Compiles the model to the ES module the page imports. A failed check leaves
 * the previous module in place and answers the compiler's own message, so the
 * dev server keeps serving instead of dying on a half-written law.
 */
export function buildLogic(): Built {
  try {
    for (const [from, to] of [
      ["game.bend", "src/game.mjs"],
      ["town.bend", "src/town.mjs"],
      ["world.bend", "src/world.mjs"],
      ["parcels.bend", "src/parcels.mjs"],
    ]) {
      execFileSync(findBend(), [`${BEND_DIR}/${from}`, "-o", to], {
        stdio: "pipe",
        encoding: "utf8",
      });
    }
    return { ok: true, output: "" };
  } catch (error) {
    const failed = error as { stdout?: string; stderr?: string; message: string };
    return { ok: false, output: `${failed.stdout ?? ""}${failed.stderr ?? ""}` || failed.message };
  }
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    const built = buildLogic();
    if (!built.ok) {
      console.error(built.output);
      process.exitCode = 1;
    }
  } else if (args[0] === "proof") {
    runBend([`${BEND_DIR}/PROOF.bend`, ...args.slice(1)]);
  } else {
    runBend(args);
  }
}
