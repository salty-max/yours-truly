/**
 * The letters: letters/<zone>/<writer>.md (English) and
 * i18n/<locale>/letters/<zone>/<writer>.md (a translation), into
 *
 *   addon/YoursTruly/Letters_Classic.lua, Letters_Forever.lua: each game's
 *     letters, those its `client` names, checked in that game's database
 *     (wow-data's, at its pins): the anchor quests, the writer, the place.
 *     For each: its quests (all to be turned in), the writer, the side, the
 *     place (an area id: the place line, the client's name), the zone it
 *     counts in (the place's top area, "Westfall: 1 of 2") and its level
 *     (the anchors' highest: the backlog's order).
 *   addon/YoursTruly/Letters_<locale>.lua: every language's texts (the
 *     translation, else the English, esMX esES's with its own names from
 *     i18n/esMX/regional.json): greeting, body, sign-off, P.S., and
 *     the places Classic Era's client names otherwise
 *     (i18n/<locale>/classic-names.json), swapped in there by the addon.
 *   i18n/names.json: the writers' and anchors' names, every language, each
 *     game's, the client's (for scripts/locales.ts). A name a language lacks
 *     is left out: the book names it another way.
 *
 * A letter file: front matter (id, quest or quests: [a, b], npc, side
 * alliance|horde|neutral, client both|classic|forever, place), the writer's
 * card (for people), then "## Letter": the greeting (the first paragraph),
 * the body, the sign-off (the last paragraph not starting "P.S.", its lines
 * kept), any P.S. A translation: the same front matter, only "## Letter".
 *
 * The rules the build can check (docs/letters.md, docs/voices.md):
 *   - an anchor, a writer or a place missing from a game the letter claims
 *   - no semicolons in any language (the gender tokens' own aside), plain
 *     ASCII in the English, the game's tokens only ($N, $C, $R, $gm:f;)
 *   - no game words, no time a late letter breaks (yesterday, last week)
 *   - the body's length: 70 to 180 words in English (said outside 100 to
 *     150), a translation up to a fifth longer
 *   - a translation's front matter, tokens and P.S. its English's, and
 *     stamped with it (i18n/<locale>/letters-stamp.json, --stamp): an English
 *     letter changed since is said
 *
 *   bun scripts/letters.ts           write them
 *   bun scripts/letters.ts --check   fail if one isn't up to date or a rule breaks
 *   bun scripts/letters.ts --stamp   record each translation's English as read
 *   bun scripts/letters.ts --names   list the game's names each English letter
 *                                    holds, those outside its chain marked, for
 *                                    a person to look at (nothing written)
 */
import { createHash } from "node:crypto";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type * as WowDb from "../../wow-data/src/db";
import { LOCALES } from "./locales-lib";
import { familyPath } from "./root";

// through the family folder, from a worktree too (scripts/root.ts)
const { openDb } = (await import(familyPath("wow-data", "src", "db.ts"))) as typeof WowDb;

const ROOT = join(import.meta.dir, "..");
const ADDON = join(ROOT, "addon", "YoursTruly");
type Game = "classic" | "forever";
const GAMES: Game[] = ["classic", "forever"];
const TRANSLATED = ["frFR", "deDE", "esES"];
// (a language that reads another's letters, its own names swapped in: i18n/<locale>/regional.json)
const BORROWS: Record<string, string> = { esMX: "esES" };
// (the client's English is enUS: enGB reads the same names)
const SOURCE_LOCALE: Record<string, string> = { enGB: "enUS" };
const SIDES: Record<string, string> = { alliance: "A", horde: "H", neutral: "N" };
const CLIENTS: Record<string, Game[]> = { both: ["classic", "forever"], classic: ["classic"], forever: ["forever"] };
// (the body's words in English: the plan's 100 to 150, terse from 70, a few big to 180)
const LENGTH = { lo: 100, hi: 150, min: 70, max: 180 };
const BANNED: Record<string, RegExp> = {
  en: /\b(quests?|level(s|ed)?|loot|yesterday|tomorrow|today|last (week|night|month)|this morning)\b/i,
  fr: /\b(quêtes?|niveaux?|butin|hier|demain|la semaine dernière|ce matin)\b/i,
  de: /\b(quests?|stufen?|beute|gestern|heute|vorgestern|letzte woche|letzten monat|letzte nacht)\b/i,
  // ("mañana" is tomorrow, "la mañana" or "cada mañana" the morning, which "esta mañana" bans)
  es: /\b(misi[oó]n|misiones|nivel(es)?|botín|ayer|hoy|anoche|esta mañana|la semana pasada|el mes pasado)\b|(?<!\b(la|las|cada|una|por la) )\bmañana\b/i,
};
// (as written: "morgen" is tomorrow, "Morgen" the morning, which "heute" bans)
const BANNED_CASED: Record<string, RegExp> = { de: /\bmorgen\b/ };
// (the game's names that hold a banned word: Booty Bay's Spanish "botín")
const NAMES_OK: Record<string, RegExp> = { es: /Bahía del Botín/g };

type Letter = {
  key: string;
  file: string;
  meta: Record<string, string>;
  paragraphs: string[];
  greeting: string;
  body: string[];
  signoff: string;
  ps: string[];
};

function frontMatter(text: string): [Record<string, string>, string] {
  const m = text.match(/^---\n([\s\S]*?)\n---\n/);
  if (!m) return [{}, text];
  const meta: Record<string, string> = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^(\w+):\s*(.*)$/);
    if (kv) meta[kv[1]] = kv[2].trim();
  }
  return [meta, text.slice(m[0].length)];
}

const problems: string[] = [];
const notes: string[] = [];

function read(dir: string): Map<string, Letter> {
  const out = new Map<string, Letter>();
  if (!existsSync(dir)) return out;
  for (const zone of readdirSync(dir).sort()) {
    const folder = join(dir, zone);
    if (!existsSync(folder) || zone.startsWith(".")) continue;
    for (const f of readdirSync(folder)
      .filter((f) => f.endsWith(".md"))
      .sort()) {
      const key = `${zone}/${f.replace(/\.md$/, "")}`;
      const file = `${folder.slice(ROOT.length + 1)}/${f}`;
      const [meta, rest] = frontMatter(readFileSync(join(folder, f), "utf8"));
      const section = rest.split(/^## Letter\n/m)[1];
      if (section === undefined) {
        problems.push(`${file}: no "## Letter"`);
        continue;
      }
      // (a paragraph per blank line; a sign-off keeps its lines)
      const paragraphs = section
        .trim()
        .split(/\n\s*\n/)
        .map((p) => p.trim())
        .filter(Boolean);
      // (P.S., the French P.-S., the Spanish P. D.)
      const isPS = (p: string) => /^P\.(-?S| ?D)\./.test(p);
      const main = paragraphs.filter((p) => !isPS(p));
      const ps = paragraphs.filter(isPS);
      if (main.length < 3) {
        problems.push(`${file}: a greeting, a body and a sign-off at least`);
        continue;
      }
      if (paragraphs.findIndex(isPS) !== -1 && paragraphs.findIndex(isPS) < paragraphs.length - ps.length)
        problems.push(`${file}: a P.S. comes last`);
      out.set(key, {
        key,
        file,
        meta,
        paragraphs,
        greeting: main[0],
        body: main.slice(1, -1),
        signoff: main[main.length - 1],
        ps,
      });
    }
  }
  return out;
}

const tokensOut = (t: string) => t.replace(/\$g[^:;]*:[^;]*;/g, "X");
const words = (l: Letter) =>
  tokensOut([...l.body, ...l.ps].join(" "))
    .split(/\s+/)
    .filter((w) => /[\p{L}\p{N}$]/u.test(w)).length;
const text = (l: Letter) => l.paragraphs.join("\n\n");
const tokens = (t: string) =>
  [...t.matchAll(/\$[NCR]\b/g)]
    .map((m) => m[0])
    .sort()
    .join(",");
// (Mealbook's: the English letter's paragraphs as written)
const hash = (l: Letter) => createHash("sha256").update(text(l)).digest("hex").slice(0, 12);
const questsOf = (l: Letter): number[] => {
  if (l.meta.quests) return JSON.parse(l.meta.quests);
  return l.meta.quest ? [Number(l.meta.quest)] : [];
};

// A borrowing language's own names in its lender's letters (the Codex's way):
// i18n/<locale>/regional.resolved.json (addon-kit/regional.ts: wow-data's names and
// regional.json's words), the longest first, applied once, no cascade.
function regionalWords(locale: string): (text: string) => string {
  const file = join(ROOT, "i18n", locale, "regional.resolved.json");
  if (!existsSync(file)) return (t) => t;
  const names: Record<string, string> = JSON.parse(readFileSync(file, "utf8"));
  const esc = (x: string) => x.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const keys = Object.keys(names).sort((a, b) => b.length - a.length);
  const pattern = new RegExp(`(?<![\\p{L}\\d])(?:${keys.map(esc).join("|")})(?![\\p{L}\\d])`, "gu");
  return (t) => t.replace(pattern, (found) => names[found]);
}

function verifyText(l: Letter, lang: string) {
  const t = text(l);
  if (tokensOut(t).includes(";")) problems.push(`${l.file}: a semicolon`);
  if (lang === "en" && /[^\x20-\x7e\n]/.test(t)) problems.push(`${l.file}: not plain ASCII`);
  const stray = tokensOut(t).match(/\$(?![NCR]\b)\w*/);
  if (stray) problems.push(`${l.file}: a token the game doesn't have: ${stray[0]}`);
  if (/\$g[^;]*$/m.test(t.replace(/\$g[^:;]*:[^;]*;/g, ""))) problems.push(`${l.file}: a gender token not closed`);
  const plain = NAMES_OK[lang] ? tokensOut(t).replace(NAMES_OK[lang], "") : tokensOut(t);
  const banned = plain.match(BANNED[lang]) ?? (BANNED_CASED[lang] ? plain.match(BANNED_CASED[lang]) : null);
  if (banned) problems.push(`${l.file}: "${banned[0]}" (a game word, or a time a late letter breaks)`);
}

const english = read(join(ROOT, "letters"));
const ids = new Map<number, string>();
for (const l of english.values()) {
  const id = Number(l.meta.id);
  if (!Number.isInteger(id) || id <= 0) problems.push(`${l.file}: no id`);
  else if (ids.has(id)) problems.push(`${l.file}: id ${id} is also ${ids.get(id)}'s`);
  else ids.set(id, l.key);
  if (!SIDES[l.meta.side]) problems.push(`${l.file}: side ${l.meta.side} (alliance, horde or neutral)`);
  if (!CLIENTS[l.meta.client]) problems.push(`${l.file}: client ${l.meta.client} (both, classic or forever)`);
  if (!questsOf(l).length) problems.push(`${l.file}: no quest`);
  if (!Number(l.meta.npc)) problems.push(`${l.file}: no npc`);
  if (!Number(l.meta.place)) problems.push(`${l.file}: no place`);
  verifyText(l, "en");
  const n = words(l);
  if (n < LENGTH.min || n > LENGTH.max) problems.push(`${l.file}: ${n} words, outside ${LENGTH.min} to ${LENGTH.max}`);
  else if (n < LENGTH.lo || n > LENGTH.hi) notes.push(`${l.file}: ${n} words (${LENGTH.lo} to ${LENGTH.hi}, terse or big)`);
}

// ── each game: the anchors, the writers, the places, checked; zones, levels, names
type Fact = { id: number; key: string; quests: number[]; npc: number; side: string; place: number; zone: number; level: number; races?: number; classes?: number };
type Names = { npcs: Record<number, string>; quests: Record<number, string> };

function gameData(game: Game) {
  const db = openDb(game);
  const all = <T>(sql: string, ...args: (string | number)[]) => db.query(sql).all(...args) as T[];
  const facts: Fact[] = [];
  const area = (id: number) => all<{ ID: number; ParentAreaID: number }>("SELECT ID, ParentAreaID FROM client_AreaTable WHERE ID = ?", id)[0];
  for (const l of [...english.values()].sort((a, b) => Number(a.meta.id) - Number(b.meta.id))) {
    if (!CLIENTS[l.meta.client]?.includes(game)) continue;
    const quests = questsOf(l);
    const npc = Number(l.meta.npc);
    const place = Number(l.meta.place);
    let level = 0;
    let missing = false;
    // (who can earn it: the anchors' race and class masks, every one's bits)
    let races = 0;
    let classes = 0;
    const and = (a: number, b: number) => (!a ? b : !b ? a : Number(BigInt(a) & BigInt(b)));
    for (const q of quests) {
      const row = all<{ level: number | null; races: number | null; classes: number | null }>("SELECT level, races, classes FROM quest WHERE id = ?", q)[0];
      if (!row) {
        problems.push(`${l.file}: quest ${q} isn't in ${game}.db (client: ${l.meta.client})`);
        missing = true;
      } else {
        level = Math.max(level, row.level ?? 0);
        // (two anchors no race or class can both take: a letter nobody earns, never "anyone")
        if (races && row.races && !and(races, row.races)) problems.push(`${l.file}: its anchors' race masks share no race (${game})`);
        if (classes && row.classes && !and(classes, row.classes)) problems.push(`${l.file}: its anchors' class masks share no class (${game})`);
        races = and(races, row.races ?? 0);
        classes = and(classes, row.classes ?? 0);
      }
    }
    if (!all("SELECT id FROM creature WHERE id = ?", npc).length) {
      problems.push(`${l.file}: npc ${npc} isn't in ${game}.db`);
      missing = true;
    }
    let top = area(place);
    if (!top) {
      problems.push(`${l.file}: area ${place} isn't in ${game}'s client`);
      missing = true;
    }
    // (the zone: the place's top area, the one the count shows)
    for (let i = 0; top && top.ParentAreaID && i < 6; i++) top = area(top.ParentAreaID) ?? top;
    if (missing) continue;
    facts.push({ id: Number(l.meta.id), key: l.key, quests, npc, side: SIDES[l.meta.side], place, zone: top.ID, level, races: races || undefined, classes: classes || undefined });
  }
  const nameOf = (kind: string, id: number, locale: string) =>
    all<{ name: string; source: string }>("SELECT name, source FROM name WHERE kind = ? AND id = ? AND locale = ?", kind, id, locale)[0];
  const names: Record<string, Names> = {};
  for (const locale of LOCALES) {
    const from = SOURCE_LOCALE[locale] ?? locale;
    const pick = (kind: string, idsOf: Iterable<number>) => {
      const out: Record<number, string> = {};
      for (const id of [...new Set(idsOf)].sort((a, b) => a - b)) {
        const n = nameOf(kind, id, from);
        // (a name the database gives only as the English its client shows is no translation)
        if (n && (from === "enUS" || n.source !== "english")) out[id] = n.name;
      }
      return out;
    };
    names[locale] = { npcs: pick("creature", facts.map((f) => f.npc)), quests: pick("quest", facts.flatMap((f) => f.quests)) };
  }
  for (const f of facts) {
    if (!names.enUS.npcs[f.npc]) problems.push(`${english.get(f.key)?.file}: npc ${f.npc} has no English name in ${game}.db`);
    for (const q of f.quests) if (!names.enUS.quests[q]) problems.push(`${english.get(f.key)?.file}: quest ${q} has no English name in ${game}.db`);
  }
  // the races whose bit in a quest's race mask isn't their id's (the client's
  // PlayableRaceBit: Forever's Skyborne are races 95 and 96, bits 32 and 33)
  const raceBits = Object.fromEntries(
    all<{ ID: number; PlayableRaceBit: number }>(
      "SELECT ID, PlayableRaceBit FROM client_ChrRaces WHERE PlayableRaceBit >= 0 AND PlayableRaceBit != ID - 1 ORDER BY ID",
    ).map((r) => [r.ID, r.PlayableRaceBit]),
  );
  return { db, all, facts, names, raceBits };
}

const lua = (v: unknown): string => {
  if (v === null || v === undefined) return "nil";
  if (typeof v === "number") return String(v);
  if (typeof v === "boolean") return v ? "true" : "false";
  if (typeof v === "string") return JSON.stringify(v);
  if (Array.isArray(v)) return `{ ${v.map(lua).join(", ")} }`;
  const entries = Object.entries(v as Record<string, unknown>).filter(([, x]) => x !== undefined && x !== null);
  return `{ ${entries.map(([k, x]) => `${/^\d+$/.test(k) ? `[${k}]` : k} = ${lua(x)}`).join(", ")} }`;
};
const q = (s: string) => `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n")}"`;

function factsLua(game: Game, facts: Fact[], raceBits: Record<number, number>): string {
  const pins = JSON.parse(readFileSync(familyPath("wow-data", "pins.json"), "utf8"));
  const b = pins.builds[game];
  const lines = [
    `-- Generated by scripts/letters.ts from letters/ and wow-data's ${game}.db (client ${b.product} ${b.build}):`,
    "-- edit those, never this file.",
    "--   letters[id] = { quests (all turned in), npc (the writer), side (A, H, N), place (an area),",
    "--                   zone (the place's top area), level (the anchors' highest), key,",
    "--                   races, classes (the anchors' masks: who can earn it; none: anyone) }",
    "--   raceBits[race] = its bit in a race mask, where it isn't the race's id less one",
    "local _, ns = ...",
    "ns.data = {",
    `  game = ${lua(game)},`,
    `  raceBits = ${lua(raceBits)},`,
    "  letters = {",
  ];
  for (const f of facts)
    lines.push(
      `    [${f.id}] = ${lua({ quests: f.quests, npc: f.npc, side: f.side, place: f.place, zone: f.zone, level: f.level, races: f.races, classes: f.classes, key: f.key })},`,
    );
  lines.push("  },", "}");
  return `${lines.join("\n")}\n`;
}

function textsLua(locale: string, letters: Map<string, Letter>, swaps: Record<string, string>): string {
  const lender = BORROWS[locale];
  const from = TRANSLATED.includes(locale)
    ? `i18n/${locale}/letters/`
    : lender
      ? `i18n/${lender}/letters/ and i18n/${locale}/regional.json`
      : "letters/";
  const lines = [
    `-- Generated by scripts/letters.ts from ${from}: edit those, not this file.`,
    "-- letterTexts[id] = { greeting, body = { paragraph, ... }, signoff (its lines), ps = { paragraph, ... } }",
    "local _, ns = ...",
    "ns.letterTexts = {",
  ];
  for (const en of [...english.values()].sort((a, b) => Number(a.meta.id) - Number(b.meta.id))) {
    const l = letters.get(en.key) ?? en;
    const ps = l.ps.length ? `, ps = { ${l.ps.map(q).join(", ")} }` : "";
    lines.push(`  [${en.meta.id}] = { greeting = ${q(l.greeting)}, body = { ${l.body.map(q).join(", ")} }, signoff = ${q(l.signoff)}${ps} },`);
  }
  lines.push("}");
  const pairs = Object.entries(swaps);
  lines.push("-- (the places Classic Era's client names otherwise, swapped in there)");
  lines.push(`ns.classicNames = { ${pairs.map(([a, b]) => `[${q(a)}] = ${q(b)}`).join(", ")} }`);
  return `${lines.join("\n")}\n`;
}

// ── the translations: checked against their English, stamped
const translations = new Map<string, Map<string, Letter>>();
for (const locale of TRANSLATED) {
  const mine = read(join(ROOT, "i18n", locale, "letters"));
  translations.set(locale, mine);
  for (const [k, l] of mine) {
    const en = english.get(k);
    if (!en) {
      problems.push(`${l.file}: no English letter`);
      continue;
    }
    for (const f of ["id", "quest", "quests", "npc", "side", "client", "place"])
      if ((l.meta[f] ?? "") !== (en.meta[f] ?? "")) problems.push(`${l.file}: ${f} isn't its English's (${en.meta[f] ?? "none"})`);
    verifyText(l, locale.slice(0, 2));
    if (tokens(text(l)) !== tokens(text(en))) problems.push(`${l.file}: its tokens aren't its English's (${tokens(text(en)) || "none"})`);
    if (!!l.ps.length !== !!en.ps.length) problems.push(`${l.file}: a P.S. in one language only`);
    const n = words(l);
    const max = Math.ceil(words(en) * 1.3);
    if (n > LENGTH.max * 1.2) problems.push(`${l.file}: ${n} words, past ${LENGTH.max * 1.2}`);
    else if (n > max) notes.push(`${l.file}: ${n} words, a third longer than its English (${words(en)})`);
  }
  for (const k of english.keys()) if (!mine.has(k)) notes.push(`${locale}: ${k} not translated yet`);
  const stampFile = join(ROOT, "i18n", locale, "letters-stamp.json");
  const stamps: Record<string, string> = existsSync(stampFile) ? JSON.parse(readFileSync(stampFile, "utf8")) : {};
  const fresh: Record<string, string> = {};
  for (const k of [...mine.keys()].sort()) {
    const en = english.get(k);
    if (!en) continue;
    fresh[k] = hash(en);
    if (stamps[k] !== hash(en)) notes.push(`${locale}: ${k}: its English changed since it was translated (--stamp once read)`);
  }
  if (process.argv.includes("--stamp") && mine.size) writeFileSync(stampFile, `${JSON.stringify(fresh, null, 2)}\n`);
}

const args = process.argv.slice(2);
const check = args.includes("--check");
const games = new Map(GAMES.map((g) => [g, gameData(g)]));

// ── --names: the game's names in each English letter, for a person to look at
if (args.includes("--names")) {
  const { all } = games.get("classic")!;
  type Named = { kind: string; id: number; name: string };
  const known: Named[] = all<Named>(
    "SELECT kind, id, name FROM name WHERE locale = 'enUS' AND kind IN ('creature', 'area', 'item', 'quest', 'object') AND length(name) >= 4",
  ).filter((n) => /^[A-Z]/.test(n.name));
  for (const l of [...english.values()].sort((a, b) => Number(a.meta.id) - Number(b.meta.id))) {
    // (the chain: the anchors and every quest before them, their givers, enders, objectives and rewards)
    const chain = new Set<number>();
    const walk = (id: number) => {
      if (chain.has(id)) return;
      chain.add(id);
      for (const p of all<{ prev_id: number }>("SELECT DISTINCT prev_id FROM quest_prereq WHERE quest_id = ? AND prev_id > 0", id)) walk(p.prev_id);
    };
    for (const a of questsOf(l)) walk(a);
    const near = new Set<string>([`creature:${l.meta.npc}`, `area:${l.meta.place}`]);
    for (const c of chain) {
      near.add(`quest:${c}`);
      for (const r of all<{ kind: string; entity_id: number }>("SELECT kind, entity_id FROM quest_relation WHERE quest_id = ?", c))
        near.add(`${r.kind}:${r.entity_id}`);
      for (const o of all<{ kind: string; target_id: number }>("SELECT kind, target_id FROM quest_objective WHERE quest_id = ?", c))
        near.add(`${o.kind === "source" ? "item" : o.kind}:${o.target_id}`);
      for (const r of all<{ ref_id: number }>("SELECT ref_id FROM quest_reward WHERE quest_id = ? AND kind IN ('item', 'choice')", c))
        near.add(`item:${r.ref_id}`);
    }
    const t = text(l);
    const found = new Map<string, Named[]>();
    for (const n of known) {
      const at = t.indexOf(n.name);
      if (at < 0) continue;
      const before = t[at - 1] ?? " ";
      const after = t[at + n.name.length] ?? " ";
      if (/[A-Za-z]/.test(before) || /[A-Za-z]/.test(after)) continue;
      const list = found.get(n.name) ?? [];
      list.push(n);
      found.set(n.name, list);
    }
    // (the longest names only: "Webwood Spider" over "Webwood")
    const names = [...found.keys()].filter((n) => ![...found.keys()].some((m) => m !== n && m.includes(n)));
    const lines = names.sort().map((name) => {
      const hits = found.get(name)!;
      const inChain = hits.some((h) => near.has(`${h.kind}:${h.id}`));
      return `    ${inChain ? " " : "?"} ${name} (${hits.slice(0, 3).map((h) => `${h.kind} ${h.id}`).join(", ")}${hits.length > 3 ? ", ..." : ""})`;
    });
    console.log(`${l.key} (${l.meta.id}): chain ${[...chain].sort((a, b) => a - b).join(", ")}`);
    for (const line of lines) console.log(line);
  }
  console.log("(?: a name the chain doesn't hold: look whether the letter may name it)");
  process.exit(0);
}

// ── the files
const files: Record<string, string> = {};
const names: Record<string, Record<string, Names>> = {};
for (const [game, d] of games) {
  files[`Letters_${game === "classic" ? "Classic" : "Forever"}.lua`] = factsLua(game, d.facts, d.raceBits);
  for (const [locale, n] of Object.entries(d.names)) (names[locale] ??= {})[game] = n;
  d.db.close();
}
for (const locale of LOCALES) {
  const swapsOf = (loc: string): Record<string, string> => {
    const file = join(ROOT, "i18n", loc, "classic-names.json");
    return TRANSLATED.includes(loc) && existsSync(file) ? JSON.parse(readFileSync(file, "utf8")) : {};
  };
  const lender = BORROWS[locale];
  if (lender) {
    // (the lender's letters and swaps, this client's names in them)
    const words = regionalWords(locale);
    const mine = new Map(
      [...(translations.get(lender) ?? new Map()).entries()].map(([k, l]) => [
        k,
        {
          ...l,
          file: `${l.file} (as ${locale})`,
          paragraphs: l.paragraphs.map(words),
          greeting: words(l.greeting),
          body: l.body.map(words),
          signoff: words(l.signoff),
          ps: l.ps.map(words),
        },
      ]),
    );
    // (its names checked like any text: a semicolon or a banned word in regional.json)
    for (const l of mine.values()) verifyText(l, lender.slice(0, 2));
    // (its own Classic Era swaps where its clients differ from the lender's, else the lender's in its names)
    const own = join(ROOT, "i18n", locale, "classic-names.json");
    const swaps = existsSync(own)
      ? JSON.parse(readFileSync(own, "utf8"))
      : Object.fromEntries(Object.entries(swapsOf(lender)).map(([a, b]) => [words(a), words(b)]));
    files[`Letters_${locale}.lua`] = textsLua(locale, mine, swaps);
  } else files[`Letters_${locale}.lua`] = textsLua(locale, translations.get(locale) ?? new Map(), swapsOf(locale));
}

for (const n of notes) console.log(`  ${n}`);
if (problems.length) {
  for (const p of problems) console.error(`✗ ${p}`);
  process.exit(1);
}
let stale = false;
const write = (path: string, want: string) => {
  const have = existsSync(path) ? readFileSync(path, "utf8") : "";
  if (have === want) return;
  if (check) {
    console.error(`✗ ${path.slice(ROOT.length + 1)} is not up to date: bun scripts/letters.ts`);
    stale = true;
  } else writeFileSync(path, want);
};
for (const [f, want] of Object.entries(files)) write(join(ADDON, f), want);
write(join(ROOT, "i18n", "names.json"), `${JSON.stringify(names, null, 1)}\n`);
if (stale) process.exit(1);
const per = [...games].map(([g, d]) => `${g} ${d.facts.length}`).join(", ");
console.log(`✓ ${english.size} letters (${per}), ${[...translations.values()].reduce((s, m) => s + m.size, 0)} translated`);
