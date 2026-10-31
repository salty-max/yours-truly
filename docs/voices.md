# Yours Truly's voices

The rules the letters are written and read by: what is ours and what is the
game's, how a letter reads, what it never does, and the register of each
writer in French, German and Spanish. The letters are
`letters/<zone>/<writer>.md`, each with **its own card** (Who, The voice,
Never, French, The game's and Ours): the rules travel with the text, and the
card is the writer's voice, this file is everyone's. See `docs/letters.md` for
the file layout and the build. The plan (which chains earn a letter, the
waves) is `../ideas/letters.md` and the six first writers' drafts
`../ideas/letters-voices.md`, both planning and outside git. For two letters
to hear the rules by, read `letters/westfall/gryan-stoutmantle.md` (plain and
grave) and `letters/the-barrens/gazlowe.md` (quick and funny).

## What is ours and what is the game's

A letter is a person, not a chronicle: the Codex's rule (nothing a source
does not give) would leave nothing to write after "thank you".

- **Ours:** the writer's life since the chain (small news, the household, a
  child's question, the weather on the plains), their feelings and opinions,
  their manners on paper (how they greet, sign, misspell, ramble).
- **The game's, exactly:** who the writer is (by id: name, title, race, where
  they stand), what the player did (the quests the anchor requires, as their
  texts tell them), what happened (the chain's outcome as its texts tell it).
- **The world stays as the game shows it.** What we invent stays small and
  off-screen: nothing the player could go and look for and not find (no new
  building, no NPC standing somewhere new). What the game itself says happens
  off-screen may be told.
- **Respawns.** A killed enemy is never said to be gone for good when the
  game brings it back (Borelgore, the Southsea pirates, the Defias on the
  roads).
- **Nothing anachronic** to the vanilla era or Forever: no later names
  (Mankrik's wife has none, "Olgra" is Cataclysm's), no later fates.
- **Nothing enclosed.** No item, gold, map or keepsake "inside": a player
  would look in the bags.
- **No quest.** No errand, hint or invitation the game does not keep. A
  writer may hope to see you, never ask you to come for something. Nothing
  the player could wait for either (a payment, a gift, a favour).
- **Only what the anchor requires.** A letter mentions the quests its anchor
  needs done, never an optional branch of the chain, never another letter or
  chain, another addon, or the game's words (quest, level, loot).
- **What the writer cannot know** stays out: the player's level, gear, reward
  choice (Duskwing's fur became gloves or a mantle: Nathanos does not guess
  which).
- **Spoilers.** A letter exists only after its chain ends, so the chain has
  nothing to hide, but it never mentions a later chain, an optional branch,
  or anything the player has not seen. No wink at a secret the game keeps for
  later (Lady Prestor): the letter reads the same after the reveal, perhaps
  darker.
- **Names by id.** A name in a letter is one wow-data holds (an NPC, a place,
  an item, a quest), so every language gets the client's. A name found only in
  an English quest text is left out (Gazlowe's "Vice Admiral Grezzlik" becomes
  "the trade fleet").

## How a letter reads

- **The shape.** A place line (where the writer is, the game's name by id), a
  greeting in the writer's manner, two to four short paragraphs, a closing,
  the signature (the writer's name as the game writes it, or a part of it),
  and now and then a P.S. The opening answers what happened. The middle is the
  writer's life since: ours, small, and off-screen. Concrete details belong to
  what the writer is doing, not a required symbol for each emotion. End where
  the writer would stop: an ordinary thank-you or sign-off can carry the
  voice without a last clever sentence.
- **Each writer sounds like nobody else.** The voice comes from the game
  first: how the writer talks in their own quests (Nesingwary booms, Gazlowe
  haggles, Sara questions her king). If two writers could swap a paragraph,
  one of them is wrong.
- **Dialects** show in word choice and rhythm, never in phonetic spelling: a
  troll's "mon" once in a letter at most, a goblin's sums, an orc's short
  sentences, a Forsaken's dryness.
- **What the player did** is named once, concretely, never recapped quest by
  quest. The game told it already: the letter is what it meant to someone.
- **Length.** 100 to 150 words of body (the paragraphs and any P.S., not the
  place line, greeting or signature). A terse writer (Mankrik, Nathanos) may
  stop at 70. A few big letters (Sara Balloo, Tirion Fordring) go up to 180.
  French a fifth longer.
- **Time.** No "yesterday", no "last week": a letter may arrive late (a
  character who did the chain before installing the addon gets it at the next
  mailbox, perhaps thirty levels on). "Since you left", "these days".
- **The P.S.** About one letter in four, where people put the true thing or
  the joke they could not resist. Never as a habit.
- **Never**, besides the above: a semicolon in any language, a change in the
  world the player would not find there. What else a writer never does (a real
  con, meanness, a promise the world cannot keep) is on that writer's card,
  not a rule for everyone: a cold or cutting writer stays cold or cutting.
- **Tokens.** The player's name `$N`, class `$C`, race `$R`, the game's own,
  and gendered words through the gender tokens (`$gcher:chère;`), which French
  needs often and English almost never. Plain ASCII in the English.
- Spelling is British, game names as the game spells them. (One shipped
  letter slips: "owe her a favor" in `letters/tanaris/marin-noggenfogger.md`
  should read "favour", a word change that rides the next release.)

## Registers by writer

The register is per writer and the writer's card says which. The default in
every language is the one below; the exceptions are the cards'.

| Language | Rule |
|---|---|
| French | Vouvoiement, nothing agreeing with the reader except through a gender token (`$gGamin:Gamine;`), used where a writer would naturally use a gendered word ("Chère", "Gamine"), never a rephrase that flattens the voice. Six writers tutoient, most for a reason on the card: **Thazzril** (a foreman shouting across the yard), **Bernice Stonefield** ("$gmon petit:ma petite;", an old countrywoman to a youngster), **Hawkwind**, **Gaxim Rustfizzle** (an enthusiast to his accomplice), **Iverron** (a friend's letter to the one who saved him), **Gazlowe** ("$gGamin:Gamine;"). |
| German | The writers who vouvoient in French use the client's "Ihr/Euch", the others "du". After a greeting with a comma the body starts in lower case. |
| Spanish | "Tú" for every writer, as the Spanish client's quests say it, gender tokens wherever a word agrees with the reader, greetings with a colon, postscripts "P. D.". Neutral: no "vosotros". esMX borrows esES's letters with its own names swapped in. |

**Open:** Gazlowe tutoies in his letter and vouvoies in Goodwill (whose card
cites the game's French Gazlowe, who vouvoie). The family decided on 31
October 2026 to align the letter on vous. That is a word change to a shipped
text, so it waits for a release of its own (the audit's VT-8). Until then the
card says tu.

The family's table of every addon's registers is in
`addon-kit/skills/wow-translating/SKILL.md`.

## Examples, by language

English is the base (British spelling, plain ASCII, no semicolons, short
sentences, idioms that travel). Two letters show both registers. Hawkwind
tutoies in French, uses "du" in German and "tú" in Spanish
(`letters/mulgore/hawkwind.md`):

> My mother was glad to hear you stood before Cairne, child, and her first
> thought was whether you had eaten before the climb.

> Ma mère a été heureuse d'apprendre que tu avais rencontré Cairne, mon enfant,
> et sa première pensée a été de savoir si tu avais mangé avant de monter
> là-haut.

> meine Mutter war froh zu hören, dass du vor Cairne gestanden hast, mein Kind,
> und ihr erster Gedanke war, ob du vor dem Aufstieg etwas gegessen hattest.

> Mi madre se alegró de saber que estuviste ante Cairne, joven, y lo primero
> que pensó fue si habías comido antes de subir.

Gryan Stoutmantle vouvoies (`letters/westfall/gryan-stoutmantle.md`), "Ihr" in
German, "tú" in Spanish:

> I am glad it is done, and I did not enjoy asking it of you.

> Je suis soulagé que ce soit fini, et je n'ai pris aucun plaisir à vous le
> demander.

> Ich bin froh, dass es vorbei ist, und es hat mir keine Freude gemacht, Euch
> darum zu bitten.

> Me alegro de que haya terminado, y no disfruté pidiéndotelo.

After a greeting with a comma the German body starts in lower case, and in
Spanish the greeting takes a colon (`$N:`).
