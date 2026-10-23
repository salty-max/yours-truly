-- Yours Truly played through: a first login with nothing done, a chain's last
-- quest turned in (its letter in the post, fifteen minutes of play, then the
-- next mailbox), the sealed envelope and its seal broken, the other side's
-- letters held back, the backlog found at a login and trickled in the chains'
-- order (one a visit, two when more than three wait), the panel docked beside
-- an open letter or standing alone for a mailbox addon, the book's tabs, the
-- achievements, a French reader who is a woman. FOREVER=1, LOCALE=frFR: those
-- clients.
local G = dofile("addon/test/game.lua")
local s, ns = G.state, G.ns
local count = 0
local function check(ok, what)
  if not ok then error("✗ " .. what, 2) end
  count = count + 1
end
local L, D = ns.kit.L, ns.data
local function said(text)
  for _, line in ipairs(s.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end
local function play(seconds) G.advance(seconds) end
local P = ns.panelParts
-- the letters: Gryan, Sara, Nathanos, Hawkwind, Gazlowe, Hemet; Iverron,
-- Denalan, Maybell, Bernice, Rejold, Thazz'ril, Gadrin, Mull, Sevren
local GRYAN, SARA, NATHANOS, GAZLOWE, HEMET = 1, 2, 3, 5, 6
local IVERRON, DENALAN, MAYBELL, BERNICE, REJOLD, THAZZRIL = 7, 8, 9, 10, 11, 12

-- ── every letter, as this client writes it ───────────────────────────────────
for id, l in pairs(D.letters) do
  check(ns.letterTexts[id], "a text for every letter: " .. id)
  check(#l.quests > 0 and l.npc and l.place and l.zone, "the data's facts: " .. id)
end
check(D.letters[IVERRON] and D.letters[THAZZRIL], "both sides' first-hour letters in this game")

-- ── a first login, nothing done ──────────────────────────────────────────────
G.login()
local char = YoursTrulyChar
check(char.guid == s.guid, "the book is this character's")
check(next(char.letters) == nil, "nothing earned, nothing posted")
for _, id in ipairs(ns.letters()) do
  check(ns.writer(id) ~= L["A friend"], "every writer named in this language: " .. id)
  check(ns.chain(id), "every chain named: " .. id)
end

-- ── a chain's last quest turned in ───────────────────────────────────────────
G.turnIn(3522) -- (Iverron's Antidote)
check(char.letters[IVERRON] and not char.letters[IVERRON].delivered, "Iverron's letter in the post")
check(#s.printed == 0, "and nothing said: no notice before the mailbox")
G.mailbox(true)
check(not ns.panelLetter(), "a mailbox too soon: nothing, and no panel")
G.mailbox(false)
play(ns.POST - 5)
check(#ns.due() == 0, "not before fifteen minutes of play")
play(10)
check(#ns.due() == 1, "then due")
G.mailbox(true)
check(char.letters[IVERRON].delivered, "delivered at the next mailbox")
check(ns.panelLetter() == IVERRON, "the panel shows it")
check(P.panel.docked, "docked to the mail window")
check(P.envelope:IsShown() and not P.scroll:IsShown(), "sealed: its envelope")
check(P.writer:GetText() == ns.writer(IVERRON), "the writer's name on it")
check(not P.next:IsShown(), "nothing else waits: no next")
-- a letter opened beside it: the panel moves beside that
OpenMailFrame:Show()
check(P.panel.point and P.panel.point[2] == OpenMailFrame, "beside the open letter")
OpenMailFrame:Hide()
check(P.panel.point and P.panel.point[2] == InboxFrame, "and back beside the inbox")
-- the seal broken
G.forget()
P.envelope.scripts.OnClick(P.envelope)
local paged = false
for _, c in ipairs(s.calls) do
  if c[1] == "PlaySound" and c[2] == SOUNDKIT.IG_ABILITY_PAGE_TURN then paged = true end
end
check(paged, "the page's sound")
check(char.letters[IVERRON].read, "read")
check(P.scroll:IsShown() and not P.envelope:IsShown(), "open: its words")
local text = P.main:GetText()
check(text:find("Tester", 1, true) and not text:find("$", 1, true), "the reader's name filled in, no token left")
check(P.place:GetText() == ns.place(IVERRON), "the place line, the client's name")
check(P.footer:GetText():find(ns.chain(IVERRON), 1, true), "under it, the chain it answers")
check(ns.earnedMilestone("first-seal"), "the first seal broken: an achievement")
check(said("[" .. L["The First Seal"] .. "]"), "said in chat")
check(YoursTrulyBanner1 and YoursTrulyBanner1:IsShown(), "and on a banner")
G.mailbox(false)
check(not P.panel:IsShown(), "the mailbox closed: the panel too")

-- ── the other side's, and both sides' ────────────────────────────────────────
G.turnIn(5441) -- (Lazy Peons: the Horde's)
check(not char.letters[THAZZRIL], "the other side's writer doesn't write")
G.turnIn(888, false) -- (Stolen Booty: the game tells it before flagging it)
check(char.letters[GAZLOWE], "a neutral writer writes to either side")
play(60)

-- ── the backlog ──────────────────────────────────────────────────────────────
for _, q in ipairs({ 166, 700, 114, 87, 414, 6163 }) do
  s.done[q] = true
end
G.login()
check(char.letters[GRYAN] and char.letters[GRYAN].backlog, "a chain done before: found at the login")
check(not char.letters[NATHANOS], "not the other side's")
check(#s.printed == 0 or not said("letter"), "quietly")
play(ns.POST + 1)
G.mailbox(true)
-- (five due: Gazlowe's, posted first, then the backlog in the chains' order)
check(
  char.letters[GAZLOWE].delivered and char.letters[MAYBELL].delivered,
  "more than three wait: two delivered, oldest first"
)
check(not char.letters[BERNICE].delivered and not char.letters[SARA].delivered, "the rest still in the post")
check(ns.panelLetter() == GAZLOWE and P.next:IsShown(), "the first sealed, and a next")
P.next.scripts.OnClick(P.next)
check(ns.panelLetter() == MAYBELL, "next: the second")
G.mailbox(false)
G.mailbox(true)
check(char.letters[BERNICE].delivered and char.letters[REJOLD].delivered, "a second visit: two more")
-- (four sealed now: next goes round them all, then back to the first)
local seen = { [ns.panelLetter()] = true }
for _ = 1, 3 do
  P.next.scripts.OnClick(P.next)
  seen[ns.panelLetter()] = true
end
check(seen[GAZLOWE] and seen[MAYBELL] and seen[BERNICE] and seen[REJOLD], "next reaches every sealed letter")
P.next.scripts.OnClick(P.next)
check(ns.panelLetter() == GAZLOWE, "and comes round to the first")
G.mailbox(false)
G.mailbox(true)
check(char.letters[GRYAN].delivered and not char.letters[SARA].delivered, "then one a visit")
G.mailbox(false)
G.mailbox(true)
check(char.letters[SARA].delivered, "the last")
check(#ns.due() == 0, "the post empty")
G.mailbox(false)

-- ── a mailbox addon: the game's window hidden ────────────────────────────────
G.turnIn(930) -- (The Glowing Fruit)
play(ns.POST + 1)
s.noMailFrame = true
G.mailbox(true)
check(char.letters[DENALAN].delivered, "delivered without the game's mail window")
check(ns.panelLetter() == GAZLOWE and not P.panel.docked, "the panel on its own, the oldest sealed letter first")
G.mailbox(false)
s.noMailFrame = nil
-- (a mailbox addon that keeps the game's window open but transparent)
G.turnIn(5441) -- (nothing for the Alliance: no new letter, the sealed ones still wait)
MailFrame:SetAlpha(0)
G.mailbox(true)
check(ns.panelLetter() and not P.panel.docked, "a transparent mail window: the panel on its own")
G.mailbox(false)
MailFrame:SetAlpha(1)
-- (a language lacking the chain's name: the footer without it, no error)
G.mailbox(true)
local shown = ns.panelLetter()
local q = D.letters[shown].quests[#D.letters[shown].quests]
local name = ns.questNames[q]
ns.questNames[q] = nil
P.envelope.scripts.OnClick(P.envelope)
check(
  char.letters[shown].read and not P.footer:GetText():find(name, 1, true),
  "a chain without its name: the footer without it"
)
ns.questNames[q] = name
G.mailbox(false)

-- ── the book ─────────────────────────────────────────────────────────────────
ns.toggle()
check(YoursTrulyFrame and YoursTrulyFrame:IsShown(), "the book opens")
play(0.5)
check(YoursTrulyFrame.count:GetText():find("8", 1, true), "eight letters received")
for _, id in ipairs(ns.received()) do
  ns.openLetter(id)
  play(0.1)
end
for _, id in ipairs(ns.received()) do
  ns.read(id)
end
check(ns.readCount() == 8, "every letter received read")
check(ns.zoneLine(MAYBELL) == L["%s: %d of %d"]:format("Zone 12", 2, 2), "Elwynn's count: two of two")
check(ns.earnedMilestone("five") and ns.earnedMilestone("still-owed"), "five letters, and Gazlowe's")
check(not ns.earnedMilestone("every"), "not every letter yet: Hemet's and the later waves' still to come")
check(not ns.milestoneVisible(ns.milestoneById["hate-mail"]), "Nathanos's achievement isn't the Alliance's")
check(not ns.earnedMilestone("ten"), "eight letters: not ten yet")
if G.FOREVER then
  check(not ns.earnedMilestone("where-it-began"), "Forever: Zephras Isle's letter still to come")
else
  check(ns.earnedMilestone("where-it-began"), "every starting zone: Teldrassil, Elwynn, Dun Morogh")
end
G.turnIn(208)
-- (Forever: the Skyborne's island writes too, Elaadrin to any Alliance race the
-- quest allows, Falorne to the High Order alone: a dwarf never gets his)
if G.FOREVER then G.turnIn(92834) end
-- (and every other letter this character can earn: the waves since)
for _, id in ipairs(ns.letters()) do
  if not char.letters[id] then
    for _, q in ipairs(D.letters[id].quests) do
      G.turnIn(q)
    end
  end
end
play(ns.POST + 1)
for _ = 1, 20 do
  G.mailbox(true)
  G.mailbox(false)
  if #ns.due() == 0 then break end
end
check(#ns.due() == 0, "the backlog delivered, a mailbox at a time")
for _, id in ipairs(ns.received()) do
  ns.read(id)
end
if G.FOREVER then
  local mine = {}
  for _, id in ipairs(ns.letters()) do
    mine[id] = true
  end
  check(mine[18] and not mine[16], "Forever: Elaadrin's letter a dwarf may earn, Falorne's the High Order's alone")
end
check(ns.earnedMilestone("every") and ns.earnedMilestone("neutral"), "every letter, every neutral writer")
check(ns.earnedMilestone("ten") and ns.earnedMilestone("far-and-wide"), "ten letters, eight zones")
check(ns.earnedMilestone("where-it-began"), "every starting zone that writes")
check(
  ns.earnedMilestone("still-standing") and ns.earnedMilestone("brush") and ns.earnedMilestone("handle-with-care"),
  "the Alliance writers' own: Hinderweir's, Remtravel's, Gaxim's"
)
check(
  not ns.milestoneVisible(ns.milestoneById["double-agent"])
    and not ns.milestoneVisible(ns.milestoneById["precious-skulls"]),
  "Neeru's and Samsa's achievements aren't the Alliance's"
)
check(
  not ns.milestoneVisible(ns.milestoneById["twenty-five"]) and not ns.milestoneVisible(ns.milestoneById["capitals"]),
  "twenty-five and the capitals unlisted until the letters reach them"
)
do
  local n, shown = ns.milestoneCount()
  check(n == shown, "every listed achievement earned: " .. n .. " of " .. shown)
end
ns.openMilestones("every")
play(0.3)
check(YoursTrulyFrame.selectedTab == ns.TAB.milestones, "the achievements' tab")
ns.openTab(ns.TAB.letters)
play(0.3)

-- ── a French reader, a woman ─────────────────────────────────────────────────
if G.LOCALE == "frFR" then
  s.sex = 3
  local b = ns.letter(BERNICE)
  check(b.greeting:find("Ma petite Tester", 1, true), "the reader agreed to: a woman")
  check(not (b.greeting .. table.concat(b.body)):find("$g", 1, true), "no token left")
  local g = table.concat(ns.letter(GAZLOWE).body, " ")
  check(g:find(G.FOREVER and "Cabestan" or "Ratchet", 1, true), "Ratchet as this client writes it")
  check(not g:find(G.FOREVER and "Ratchet" or "Cabestan", 1, true), "and not the other client's")
  local sol = table.concat(ns.letter(21).body, " ") -- (Magistrate Solomon's)
  for forever, classic in pairs({
    ["Comté-du-Lac"] = "Lakeshire",
    ["Sombre-Comté"] = "Darkshire",
    Hurlevent = "Stormwind",
  }) do
    local this, other = forever, classic
    if not G.FOREVER then
      this, other = classic, forever
    end
    check(
      sol:find(this, 1, true) and not sol:find(other, 1, true),
      this .. " as this client writes it, in Solomon's letter"
    )
  end
  s.sex = 2
end

-- ── the other side ───────────────────────────────────────────────────────────
s.faction, s.race = "Horde", 2 -- (an orc: a Horde letter's anchors allow the Horde's races)
local horde = {}
for _, id in ipairs(ns.letters()) do
  horde[id] = true
end
check(
  horde[NATHANOS] and horde[GAZLOWE] and not horde[GRYAN],
  "a Horde character's letters: the Horde's and the neutral ones"
)
check(
  ns.milestoneVisible(ns.milestoneById["double-agent"])
    and ns.milestoneVisible(ns.milestoneById["precious-skulls"])
    and not ns.milestoneById["brush"].visible(),
  "the Horde's writers' achievements, not the Alliance's (earned ones stay listed)"
)
s.faction = nil

io.write(
  ("Yours Truly: %d checks passed (%s, %s).\n"):format(count, G.LOCALE, G.FOREVER and "Forever" or "Classic Era")
)
