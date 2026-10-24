import { resolve } from "node:path";
import type { Plugin } from "vite-plus";
import { defineConfig } from "vite-plus";
import { buildLogic } from "./scripts/bend.ts";

// The model in logic/ is the source of truth; src/game.mjs is its output, so
// every dev start and build regenerates it rather than trusting a stale copy.
function lajurLogic(): Plugin {
  return {
    name: "lajur-logic",
    buildStart() {
      const built = buildLogic();
      if (!built.ok) this.error(built.output);
      this.addWatchFile("logic/game.bend");
      this.addWatchFile("logic/PROOF.bend");
    },

    // Editing the model rebuilds it rather than reloading a stale copy.
    handleHotUpdate({ file, server }) {
      if (!file.endsWith("logic/game.bend")) return;
      const built = buildLogic();
      if (!built.ok) {
        // Keep the last good module: a broken law should not take the page down.
        console.error(built.output);
        return;
      }
      const module = server.moduleGraph.getModuleById(resolve("src/game.mjs"));
      if (module) server.moduleGraph.invalidateModule(module);
      server.ws.send({ type: "full-reload" });
      return [];
    },
  };
}

const port = Number(process.env.PORT ?? 5173);

export default defineConfig({
  plugins: [lajurLogic()],
  server: { host: true, port, strictPort: true },
  preview: { host: true, port, strictPort: true },
  fmt: {},
  lint: {
    jsPlugins: [{ name: "vite-plus", specifier: "vite-plus/oxlint-plugin" }],
    rules: { "vite-plus/prefer-vite-plus-imports": "error" },
    options: { typeAware: true, typeCheck: true },
  },
});
