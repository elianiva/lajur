import { resolve } from "node:path";
import type { Plugin } from "vite-plus";
import { defineConfig } from "vite-plus";
import { buildLogic, SOURCES } from "./scripts/bend.ts";

// The model in logic/ is the source of truth; src/game.mjs is its output, so
// every dev start and build regenerates it rather than trusting a stale copy.
function lajurLogic(): Plugin {
  return {
    name: "lajur-logic",
    buildStart() {
      const built = buildLogic();
      if (!built.ok) this.error(built.output);
      for (const source of Object.keys(SOURCES)) this.addWatchFile(`logic/${source}.bend`);
      this.addWatchFile("logic/PROOF.bend");
    },

    // Editing the model rebuilds it rather than reloading a stale copy.
    handleHotUpdate({ file, server }) {
      const source = /logic\/(\w+)\.bend$/.exec(file)?.[1];
      const touched = source && SOURCES[source];
      if (!touched) return;
      const built = buildLogic();
      if (!built.ok) {
        // Keep the last good module: a broken law should not take the page down.
        console.error(built.output);
        return;
      }
      for (const name of touched) {
        const module = server.moduleGraph.getModuleById(resolve(`src/${name}.mjs`));
        if (module) server.moduleGraph.invalidateModule(module);
      }
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
  // The game, and the lab that shows every asset in src/assets.
  build: {
    rollupOptions: {
      input: { game: resolve("index.html"), lab: resolve("lab.html"), town: resolve("town.html") },
    },
  },
  fmt: {},
  lint: {
    jsPlugins: [{ name: "vite-plus", specifier: "vite-plus/oxlint-plugin" }],
    rules: { "vite-plus/prefer-vite-plus-imports": "error" },
    options: { typeAware: true, typeCheck: true },
  },
});
