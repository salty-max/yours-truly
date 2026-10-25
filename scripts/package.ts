/**
 * The addon's package: the family's (scripts/package-lib.ts, the kit's copy):
 * addon/YoursTruly as it is, one zip for every game, each game loading its own
 * TOC; its TOCs checked.
 *
 *   bun scripts/package.ts           dist/YoursTruly and dist/YoursTruly-<version>.zip
 *   bun scripts/package.ts --no-zip  the folder only (to copy into a game)
 *   bun scripts/package.ts --check   the TOCs only
 */
import { join } from "node:path";
import { run } from "./package-lib";

// (each game's own files: the letters: each game's own)
run({ root: join(import.meta.dir, ".."), name: "YoursTruly", games: { classic: ["Letters_Classic.lua"], forever: ["Letters_Forever.lua"] } });
