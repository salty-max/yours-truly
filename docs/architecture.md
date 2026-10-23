# Yours Truly's architecture

The addon file by file (the map is CLAUDE.md). The letters and their build:
`docs/letters.md`.

## The package

- `addon/YoursTruly`: one package for every game (`YoursTruly_Vanilla.toc`:
  Classic Era, 11509; `_Camelot.toc`: Forever, 16001; no TBC Anniversary:
  the family dropped it), the same but for the interface and the game's
  letters (`Letters_Classic.lua`, `Letters_Forever.lua`). Loads its letters,
  `Kit.lua` (the kit's copy, `bun run kit:sync`; never edit it),
  `Locale.lua`, `Text_[TextLocale].lua`, `Letters_[TextLocale].lua`,
  `Core.lua`, `Settings.lua`, `Achievements.lua`, `Panel.lua`, `Book.lua`,
  `LettersBook.lua`, `AchievementsBook.lua`, `Welcome.lua`, `Minimap.lua`
  (the test game loads them from the TOC).

## The files

- `Locale.lua`: the client's words (`ns.translate`, the plural rule), which
  game this is (`ns.forever`), the game's names by id from the Text file
  (`ns.names`: the writers, the quests, this game's), and `ns.agree`: the
  game's own `$gmasc:fem;` tokens, a line agreed to the reader.
- `Core.lua`: the book (`YoursTrulyChar`: played, letters, milestones; ids
  only), the events (`ns.on`), the clock (the seconds played while logged
  in, counted by the addon's own frame: `RequestTimePlayed` prints to the
  chat), the letters this character may receive (`ns.letters`: its side's
  and the neutral writers', this game's, its race's and class's by the
  anchors' masks, the client's race bits where they differ: Forever's
  Skyborne are bits 32 and 33, so a dwarf never counts Falorne's letter), the post (`QUEST_TURNED_IN`: a
  letter's last quest posts it, the game flagging the quest or not yet; at
  each login, `ns.catchUp`: every letter earned before, posted at once,
  `backlog`), the bundle (`ns.bundle`: two or more backlog letters come
  together at the next mailbox, with no wait, and `ns.untie` files them in
  the book, sealed, `bundled`: a level 60 installing the addon, or a new
  wave of letters for chains already done, gets one bundle and not a dozen
  visits of old news; one alone goes by the post), the delivery
  (`MAIL_SHOW`, once a visit until `MAIL_CLOSED`: the letters fifteen
  minutes of play in the post, oldest first, then the chain's level; one,
  two when more than three wait), the seal broken
  (`ns.read`), a letter's words (`ns.letter`: Classic Era's names swapped in
  there, agreed to the reader, `$N`, `$C`, `$R` filled, the class's name for
  a woman where the client has one), the writer's, the place's and the
  chain's names, a zone's count (`ns.zoneLine`: "Westfall: 1 of 2", only
  once that zone has written), `/yourstruly` (`achievements`, `minimap`,
  `settings`, `welcome`, `export`, `import CODE`).
- `Panel.lua`: the panel beside the mail window (`ns.showPanel` at a
  mailbox with a letter or the backlog's bundle waiting, never empty;
  `ns.hidePanel` when it closes): the bundle first when there is one, on
  the envelope's face ("From the road behind you", the count, "tied with
  string", the window titled a bundle of letters), a click untying it into
  the book, then its note on the same face (the count, "in your book now,
  sealed", a click or "Open the book" opening the book), "Next letter"
  going round the bundle and the letters waiting; the sealed envelope (the logo's wax seal, the writer, the
  place; a click breaks it, the game's page sound), the letter on the mail
  reader's own paper in its own face, scrolling as the game's reader does,
  the chain and the zone's count under it, "Next letter" while another
  waits. Docked beside the open letter (OpenMailFrame) when one is open,
  else where that would stand (beside InboxFrame); on its own, movable and
  remembered (`panelX`, `panelY`), when a mailbox addon keeps the game's
  mail window hidden.
- `Achievements.lua`: on the letters read, in three groups. Counts: the
  first seal, five, ten, twenty-five, every letter the character can
  receive. Places: letters from eight zones, from every starting zone that
  writes to the character, from each of its side's three capitals (zones by
  area id, the letter's `zone`). Writers: every neutral writer's, and eight
  writers' own, named for their letter (Nathanos's Hate Mail, Gazlowe's
  Still Owed, Hinderweir's Still Standing, Remtravel's Where Is My Brush?,
  Gaxim's Handle with Care, Neeru's Double Agent, Samsa's Precious Skulls,
  and Better Late Than Never, the Felstone parcel's: Ol' Emma's to the
  Alliance, Jeremiah Payson's to the Horde).
  Each character's own, with when and at what level; announced with the
  game's fanfare, a banner and a line in chat, quietly at the login. One a
  character can't earn isn't listed, nor one the letters don't reach yet
  (none, since the first wave's sixty-nine: twenty-five and the capitals
  were unlisted until it): a wave brings it. Earned stays listed.
- `Book.lua`: the family's window and tabs in Yours Truly's theme (the red
  of the game's sealing wax, a letter's ink warm), the parts every tab uses
  (`ns.ui`). `LettersBook.lua`: every letter delivered, newest first, each
  row its seal, writer, place and first line; the page the letter in the
  kit's aside, signed, its P.S. apart, then the chain it answers, when it
  came and its zone's count; a letter left sealed opens there too ("Break
  the seal"). Letters in the post never show. `AchievementsBook.lua`: the
  kit's board over both panels.
- `Settings.lua`: each character's settings, the kit's profiles (a code
  `YT1:...`, `/yourstruly export`, `/yourstruly import CODE`): the minimap
  button and its place (120 degrees, clear of Goodwill's 140, Mealbook's 165
  and the siblings'), the panel's place when it stands alone (never
  copied). `Welcome.lua`: the kit's welcome page, once per character.
  `Minimap.lua`: the book's button, as the siblings'.

## Artwork

The sealed parchment envelope, red wax and ivory quill mark is kept in
`assets/`, with its master, 1024px and 512px PNG exports, and exact
generation prompt. `Media/Logo.tga` is the uncompressed 256px RGBA game
texture with rounded corners. Both TOCs and `ns.ICON` use it, covering the
book, welcome page, minimap and achievement banners. `Media/Seal.tga` is its
wax seal cut round (`ns.SEAL`): a sealed letter's seal on the envelope in the
mailbox panel, in the book's list and on its page. `ns.ICON_READ` keeps the
game's open-letter icon so read letters remain distinct. Export details are
in `assets/README.md`.

## Tests

- `addon/test/game.lua` (the addon's files loaded as its TOC lists them;
  Palaver's frames, events and timers, as Goodwill's; quests done and turned
  in, the mail window, its inbox and open letter, MAIL_SHOW and MAIL_CLOSED,
  the mail's face, the client's area names, race, class and sex) and
  `addon/test/sim.lua`: a letter turned in, its fifteen minutes in the post,
  the mailbox, the envelope and its seal broken, the tokens filled, the other
  side's letters held back, a neutral writer's, the backlog as one bundle
  untied into the book (and a backlog of one by the post), the panel beside an open letter and alone for a mailbox
  addon, the book's tabs, the achievements, a French reader who is a woman,
  Classic Era's names, on Classic Era, Forever and a French client of each
  (`bun run check` runs all four).

## Languages

- Yours Truly's own words through `L` (`i18n/<locale>/words.json`, `bun run
  locales`) and the letters (`i18n/<locale>/letters/`): English and French,
  the other clients English until translated. The writers', quests' and
  places' names are the game's, by id, in the client's language.

## Not done yet

- The stores themselves: `addon/CURSEFORGE.md` is drafted and read cold
  (23 October 2026), but no CurseForge or Wago project exists yet. The name
  was checked on Wago's search (no addon by it) and by web search for
  CurseForge (none found), CurseForge's own search unreachable headless:
  its slug, `yours-truly`, is confirmed when the project is made. The
  projects' ids then go into the TOCs (`X-Curse-Project-ID`, `X-Wago-ID`)
  before the first release.
- The panel's look checked in the game: rendered offline with the game's
  paper and a serif in Morpheus's place (wago.tools, where the client's font
  is, didn't answer on 23 October 2026).
- The rest of the first wave (`../ideas/letters.md` §2): 54 letters, written
  in waves by level band.
- The opt-in collector (`K.collect`), as the siblings carry it.
