# Yours Truly

A World of Warcraft addon: the people whose quest chains you finished write
you a letter, in their own voice, about what the chain changed for them. It
waits at the next mailbox you open, sealed, in a panel beside the mail
window (never real mail: no addon can make one), and stays in the book. Planned in `../ideas/letters.md` (every call
the user's, 23 October 2026: its Decided section), the voices and their rules
in `docs/voices.md`. Started 23 October 2026. On GitHub (salty-max/yours-truly, public,
23 October 2026), released since v0.1.0. Classic Era (11509) and Forever (16001), one package. Read the
family's CLAUDE.md (`../CLAUDE.md`) first.

## Where things are

| What | Where |
|---|---|
| The addon file by file: the package, Core (the post, the mailbox), Panel, the book's tabs, Achievements, Settings, Welcome, the tests, languages | `docs/architecture.md` |
| The letters: the files, their parts, the ids, the generator (`scripts/letters.ts`) and what it checks | `docs/letters.md` |
| The letters themselves, each with its writer's card | `letters/<zone>/<writer>.md`, French, German and Spanish in `i18n/<locale>/letters/<zone>/` (esMX: esES's, `i18n/esMX/regional.json`, resolved into `regional.resolved.json` by addon-kit's regional.ts) |
| The logo, its master, exports and exact generation prompt | `assets/README.md` |
| The voices' rules: what is ours and the game's, how a letter reads, the registers by writer | `docs/voices.md` |
| The plan, the waves to come and the six first letters' history | `../ideas/letters.md`, `../ideas/letters-voices.md` |
| The store page (CurseForge, Wago), its summary (the TOCs' Notes) | `addon/CURSEFORGE.md` |

## Commands

```bash
bun run check        # kit, saved ids, letters, languages, lint, the sim on ten clients, TOCs
bun run check:ci     # what CI and the release gate run: no family folder (the kit, the saved ids and the generators' checks aside)
bun scripts/root.ts --run addon-kit/regional.ts   # esMX's game names from wow-data into i18n/esMX/regional.resolved.json (first, after a wow-data change; --check is in `check`)
bun run ids          # every table saved-ids.json lists keeps the ids it had at the fork point from origin/main
bun scripts/root.ts --run addon-kit/q.ts check -- bun run check   # the same, quiet, stamping the tree for the push
bun run package      # dist/YoursTruly-<version>.zip for a test in the game
bun run letters      # the letters again, after a letters/ edit or wow-data's change (`--stamp <language>` once that translation is read: one language, never all by default)
bun scripts/letters.ts --names   # the game's names each letter holds, those outside its chain marked, to look at
bun run kit:sync     # after a change to the kit (Kit.lua, Media, scripts/root.ts)
bun run locales      # after a new L["..."] (then --keys for i18n/words.json)
scripts/release.sh --version X.Y.Z [--hold] NOTES.md   # check, tag, push; Actions publish
```

## Hard rules

- The letters' rules are `docs/voices.md` (from the plan, `../ideas/letters.md` §1, §4, §6):
  the writer's life since the chain is ours, small and off-screen; who the
  writer is, what the player did and what happened are the game's, exactly,
  from the quests the anchor requires and nothing else. Nothing enclosed,
  no errand, nothing to wait for, nothing the writer can't know, no enemy
  gone for good that the game brings back, nothing anachronic. If two
  writers could swap a paragraph, one of them is wrong.
- Every new letter: the chain's texts from wow-data (`bun
  ../wow-data/bin/card.ts quest`), the writer's card, the English, each
  translation (French, German, Spanish) written in its own language, the
  game's names by id in every one; the prose-reader reads each language
  cold before the user does.
- The game's data comes from wow-data's databases only (`scripts/letters.ts`,
  through `scripts/root.ts`, the kit's copy). Generated files
  (`Letters_*.lua`, `Text_*.lua`, `i18n/names.json`,
  `i18n/esMX/regional.resolved.json`) are never edited by hand; `--check`
  fails a stale one.
- A letter's id never changes and is never reused: characters keep it
  (`saved-ids.json`, `bun run ids` in the check). An id leaves only with the
  user's go, under `removed`.
- Saved data (`YoursTrulyChar`) keeps ids only. Writers, quests and places
  are named by id in the client's language, never matched by an English
  name.
- Letters in plain ASCII in English, no semicolons in any language, 100 to
  150 words of body (terse from 70, a few big to 180), the game's tokens
  only. A translation is stamped against its English.
- Notice only by the minimap's mail icon (the game's own, our small one on the book's button where it can't be found) (28 October 2026, the user's call, lifting the plan's "no notice before the mailbox"): shown once a letter is due, delivered and unread, or the backlog waits. No chat line, no toast.
- `Kit.lua`, `Media/`, `scripts/root.ts` (and `root.py`), `scripts/locales-lib.ts`, `scripts/package-lib.ts`,
  `i18n/kit/` (the kit's words, translated once), `wow.yml`, `stylua.toml` and
  `addon/test/wowmock.lua` (the tests' game) are the kit's copies: edit addon-kit, then `bun run kit:sync`. The addon's
  own globals for selene are `yourstruly.yml`.
- No other addon's API, even optional (a mailbox addon is stepped aside
  for, never touched). Stepping aside for a rival is fine.
- Conventional Commits, lowercase subjects, no AI trailers. Commit locally;
  ask before any push, release or deploy. The pre-push hook wants a check
  stamp on the tree (q), which `release.sh` makes after the version bump.
