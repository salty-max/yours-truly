# The letters

Written in `../ideas/letters/` on 23 October 2026, in this layout, and moved
here as they were. The plan (which chains earn a letter, the rules of
invention, the waves): `../ideas/letters.md`; how a letter reads and the six
first writers' history: `../ideas/letters-voices.md`.

## The files

- `letters/<zone>/<writer>.md`, one writer a file: the front matter, the
  writer's card, then `## Letter`. The zone is the world zone the count
  shows ("Teldrassil: 1 of 2"): Shadowglen's letter is under `teldrassil/`,
  the Valley of Trials' under `durotar/`. The subzone is the `place`.
- **Front matter**: `id` (the letter's own number, saved by characters,
  never reused), `quest` (the anchor, or `quests: [a, b]` when several must
  all be turned in), `npc` (the writer), `side` (alliance, horde, neutral),
  `client` (both, classic, forever), `place` (an area id: the place line, in
  every language the client's name).
- **The card**: who (the chain as its texts tell it, with ids), the voice,
  never, French (tu or vous), the game's and ours. For people, not the
  build.
- **The letter**: paragraphs split by blank lines, a body paragraph on one
  line. The first paragraph is the greeting. The last paragraph not
  starting "P.S." ("P.-S." in French) is the sign-off: its lines kept as
  written (a closing, the signature, perhaps a second line). Anything after
  it starting "P.S." is a postscript. The body, counted for length (100 to
  150 words, terse from 70, big to 180), is everything between greeting and
  sign-off, plus the postscript.
- **Tokens**: `$N`, `$C`, `$R`, and `$gmasc:fem;`, the game's.
- **French**: `i18n/frFR/letters/`, the same paths, the same front matter,
  only `## Letter`. Forever's names in the text, Classic Era's swapped in by
  `i18n/frFR/classic-names.json` (Mealbook's way). The client's own
  typography where a name has it (Forever's `Sabot-d’Hiver`).
  `i18n/frFR/letters-stamp.json` holds, for each letter, the first 12 hex
  of the sha256 of its English letter's paragraphs joined by a blank line
  (Mealbook's hash): a French letter whose English changed since is due a
  read.

## The build (`scripts/letters.ts`)

Each game's letters (`Letters_Classic.lua`, `Letters_Forever.lua`): those its
`client` names, the anchors, the writer and the place checked in that
game's database, the zone (the place's top area in the client's AreaTable),
the level (the anchors' highest: the backlog's order), who can earn it (the
anchors' race and class masks, and the client's race bits where a race's
isn't its id less one). Every language's
texts (`Letters_<locale>.lua`), the translation else the English. The
writers' and anchors' names in every language (`i18n/names.json`, read by
`scripts/locales.ts`).

It refuses: an anchor, writer or place missing from a game the letter
claims; a duplicate id; a semicolon (the gender tokens' own aside);
non-ASCII English; a token the game doesn't have; a game word or a time a
late letter breaks (quest, level, loot, yesterday, last week; the French
likewise); a body outside 70 to 180 words; a translation whose front
matter, tokens or P.S. aren't its English's. It says: a body outside 100 to
150, a translation a third longer than its English, one not translated yet,
one whose English changed since its stamp.

`--names` lists the game's names each English letter holds, and marks those
its chain (the anchors and every quest before them, their givers, enders,
objectives and rewards) doesn't hold, for a person to look at: most are the
quests' own words (VanCleef, Stratholme), each on the writer's card.

## The ids

| id | letter | wave |
|---|---|---|
| 1 | westfall/gryan-stoutmantle | sample |
| 2 | ironforge/sara-balloo | sample |
| 3 | eastern-plaguelands/nathanos-blightcaller | sample |
| 4 | mulgore/hawkwind | sample |
| 5 | the-barrens/gazlowe | sample |
| 6 | stranglethorn-vale/hemet-nesingwary | sample |
| 7 | teldrassil/iverron | first hour |
| 8 | teldrassil/denalan | first hour |
| 9 | elwynn-forest/maybell-maclure | first hour |
| 10 | elwynn-forest/bernice-stonefield | first hour |
| 11 | dun-morogh/rejold-barleybrew | first hour |
| 12 | durotar/thazzril | first hour |
| 13 | durotar/gadrin | first hour |
| 14 | mulgore/mull-thunderhorn | first hour |
| 15 | tirisfal-glades/sevren | first hour |
| 16 | zephras-isle/falorne-fallwind | first hour (Forever: the High Order) |
| 17 | zephras-isle/ventaari-brightwish | first hour (Forever: the Windshapers) |
| 18 | zephras-isle/elaadrin-evengale | Zephras Isle (Forever: the High Order) |
| 19 | zephras-isle/ayessa-dawnsinger | Zephras Isle (Forever: the Windshapers) |
| 20 | loch-modan/hinderweir | 10 to 30 |
| 21 | redridge-mountains/magistrate-solomon | 10 to 30 |
| 22 | darkshore/prospector-remtravel | 10 to 30 |
| 23 | stonetalon-mountains/gaxim-rustfizzle | 10 to 30 |
| 24 | ashenvale/raene-wolfrunner | 10 to 30 |
| 25 | darnassus/thyntel-bladeweaver | 10 to 30 |
| 26 | orgrimmar/neeru-fireblade | 10 to 30 |
| 27 | silverpine-forest/dalar-dawnweaver | 10 to 30 |
| 28 | silverpine-forest/high-executor-hadrec | 10 to 30 |
| 29 | the-barrens/mankrik | 10 to 30 |
| 30 | thunder-bluff/nara-wildmane | 10 to 30 |
| 31 | the-barrens/regthar-deathgate | 10 to 30 |
| 32 | the-barrens/mangletooth | 10 to 30 |
| 33 | the-barrens/seereth-stonebreak | 10 to 30 |
| 34 | hillsbrad-foothills/deathguard-samsa | 10 to 30 |

Zephras Isle's four (23 October 2026) are Forever's only (`client: forever`),
written from Wowhead's texts of the beta as wow-data holds them: to read
again against the launch's client (4 November 2026). Their writers' sex is
their model's (CreatureDisplayInfoExtra's DisplaySexID), as the quests don't
say.

## Read

The first hour's nine read cold twice by the prose-reader, English and
French separately, 23 October 2026, and fixed; the six samples cold-read in
`../ideas/letters-voices.md`. The 10 to 30 wave's fifteen likewise, 23
October 2026. Waiting on the user's read.

A writer's folder is the zone where the writer stands, not the chain's:
Thyn'tel Bladeweaver's chain runs through Ashenvale, she is in Darnassus;
Seereth Stonebreak's is in the Stonetalon Mountains, she stands at Honor's
Stand, in the Barrens.
