-- Yours Truly played through: a first login with nothing done, a chain's last
-- quest turned in (its letter in the post, fifteen minutes of play, then the
-- next mailbox), the list and a seal broken, the other side's
-- letters held back, the backlog found at a login and come all at the first
-- mailbox (a row each, its seal broken by the page's button, a backlog of
-- one too), the mailbox's pace (one a visit, two when more than three
-- wait), the panel docked beside
-- an open letter or standing alone for a mailbox addon, the book's tabs, the
-- achievements, a French, a German and a Spanish reader who is a woman. FOREVER=1, LOCALE=frFR, deDE, esES or esMX: those
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
check(MiniMapMailFrame:IsShown(), "a letter due: the game's own mail icon on the minimap")
MiniMapMailFrame.scripts.OnEvent(MiniMapMailFrame, "UPDATE_PENDING_MAIL")
check(MiniMapMailFrame:IsShown(), "the game hides it on its event, no real mail: ours shows it again")
s.newMail = true
MiniMapMailFrame.scripts.OnEvent(MiniMapMailFrame, "UPDATE_PENDING_MAIL")
check(MiniMapMailFrame:IsShown(), "real mail: shown, by the game's state")
s.newMail = nil
MiniMapMailFrame.scripts.OnEvent(MiniMapMailFrame, "UPDATE_PENDING_MAIL")
check(MiniMapMailFrame:IsShown(), "the real mail gone, a letter still waiting: still shown")
-- the mail window as ButtonFrameTemplate draws it: 338x424
MailFrame:SetSize(338, 424)
for _, f in ipairs({ MailFrame, OpenMailFrame }) do
  f.GetHitRectInsets = function() return 0, 0, 0, 0 end
end
G.mailbox(true)
check(P.panel:GetWidth() == 338 and P.panel:GetHeight() == 424, "the panel as big as the mail window")
check(P.panel.point and P.panel.point[4] == 0, "docked against the mail window")
if not G.FOREVER then
  check(
    P.prev.point[4] == 30 and P.next.point[4] == 305 and P.openAll.point[4] == 171,
    "the pager and the button where the inbox puts them across"
  )
  check(
    P.prev.point[5] == -398 and P.next.point[5] == -398 and P.openAll.point[5] == -398,
    "and down, on the row under the seventh"
  )
  check(P.back.point[5] == -398, "Back where the button stands")
end
check(ns.mailBadgeShown(), "delivered and unread: the icon still there")
check(char.letters[IVERRON].delivered, "delivered at the next mailbox")
check(ns.panelLetter() == "list", "the panel shows the list")
check(P.panel.docked, "docked to the mail window")
check(P.rows[1]:IsShown() and not P.rows[2]:IsShown(), "one row: the letter")
check(not P.scroll:IsShown(), "sealed: no words yet")
check(P.rows[1].name:GetText() == ns.writer(IVERRON), "the writer's name on its row")
check(P.rows[1].sub:GetText() == ns.place(IVERRON), "the place under it")
check(
  P.prev:IsShown() and P.next:IsShown() and P.openAll:IsShown(),
  "the pager and the button always there, as the inbox has them"
)
-- a letter opened beside it: the panel moves beside that
OpenMailFrame:Show()
check(P.panel.point and P.panel.point[2] == OpenMailFrame, "beside the open letter")
OpenMailFrame:Hide()
check(P.panel.point and P.panel.point[2] == InboxFrame, "and back beside the inbox")
-- the seal broken
G.forget()
P.rows[1].scripts.OnClick(P.rows[1])
local paged = false
for _, c in ipairs(s.calls) do
  if c[1] == "PlaySound" and c[2] == SOUNDKIT.IG_ABILITY_PAGE_TURN then paged = true end
end
check(paged, "the page's sound")
check(char.letters[IVERRON].read, "read")
check(ns.panelLetter() == IVERRON and P.scroll:IsShown() and not P.rows[1]:IsShown(), "open: its words")
local text = P.main:GetText()
check(text:find("Tester", 1, true) and not text:find("$", 1, true), "the reader's name filled in, no token left")
check(P.place:GetText() == ns.place(IVERRON), "the place line, the client's name")
check(P.footer:GetText():find(ns.chain(IVERRON), 1, true), "under it, the chain it answers")
check(ns.earnedMilestone("first-seal"), "the first seal broken: an achievement")
check(said("[" .. L["The First Seal"] .. "]"), "said in chat")
check(
  YoursTrulyBanner1 and YoursTrulyBanner1:IsShown(),
  "and on the game's alert (here its banner stand-in: this test game has none)"
)
G.mailbox(false)
check(not P.panel:IsShown(), "the mailbox closed: the panel too")

-- ── the other side's, and both sides' ────────────────────────────────────────
G.turnIn(5441) -- (Lazy Peons: the Horde's)
check(not char.letters[THAZZRIL], "the other side's writer doesn't write")
G.turnIn(888, false) -- (Stolen Booty: the game tells it before flagging it)
check(char.letters[GAZLOWE], "a neutral writer writes to either side")
play(60)

-- ── the backlog: all of it at the first mailbox, a row each ────────────────
for _, q in ipairs({ 166, 700, 114, 87, 414, 6163 }) do
  s.done[q] = true
end
G.login()
check(char.letters[GRYAN] and char.letters[GRYAN].backlog, "a chain done before: found at the login")
check(not char.letters[NATHANOS], "not the other side's")
check(#s.printed == 0 or not said("letter"), "quietly")
check(#ns.backlog() == 5, "five found")
play(ns.POST + 1)
check(#ns.due() == 1 and ns.due()[1] == GAZLOWE, "the backlog isn't in the post: only the fresh one is due")
G.mailbox(true)
check(char.letters[GAZLOWE].delivered, "a fresh letter still comes by the post")
for _, id in ipairs({ GRYAN, SARA, MAYBELL, BERNICE, REJOLD }) do
  check(char.letters[id].delivered and not char.letters[id].read, "the backlog's letter at the mailbox, sealed: " .. id)
end
check(#ns.backlog() == 0 and #ns.waiting() == 6, "all six waiting, none held back")
check(ns.panelLetter() == "list" and P.rows[6]:IsShown() and not P.rows[7]:IsShown(), "a row each")
-- (a sealed letter in the book: a button breaks its seal)
ns.openLetter(GRYAN)
local letterPage = YoursTrulyLetterPage
local seal = letterPage.buttonPool[1]
check(
  seal and seal:IsShown() and seal.text == L["Break the seal"] and not letterPage.chipPool[1],
  "a sealed letter in the book: a button, not a chip"
)
seal.scripts.OnClick(seal)
check(char.letters[GRYAN].read, "the button breaks the seal: " .. GRYAN)
local voice = letterPage.voices[1]
check(
  voice and voice:IsShown() and voice.sign:GetText() == ns.letter(GRYAN).signoff and #letterPage.asides == 0,
  "the letter in the book: the kit's voice, signed, no aside"
)
YoursTrulyFrame:Hide()
-- (the button: every seal still whole broken at once, the panel closed)
G.mailbox(false)
G.mailbox(true)
check(#P.rows == 7 and P.rows[5]:IsShown() and not P.rows[6]:IsShown(), "the next visit: the five still sealed")
P.openAll.scripts.OnClick(P.openAll)
check(#ns.waiting() == 0 and not P.panel:IsShown(), "open all: every seal broken, the panel closed")
G.mailbox(false)
G.mailbox(true)
check(not ns.panelLetter(), "the visit after: no panel, nothing left")
G.mailbox(false)
-- (one alone: at the mailbox like the others)
local lone = 20 -- (Hinderweir's: A Dark Threat Looms)
s.done[283] = true
G.login()
check(char.letters[lone] and char.letters[lone].backlog, "a backlog of one")
check(not ns.due()[1], "not in the post")
G.mailbox(true)
check(char.letters[lone].delivered, "it reaches the mailbox at once")
G.mailbox(false)

-- ── a mailbox addon: the game's window hidden ────────────────────────────────
G.turnIn(930) -- (The Glowing Fruit)
play(ns.POST + 1)
s.noMailFrame = true
G.mailbox(true)
check(char.letters[DENALAN].delivered, "delivered without the game's mail window")
check(P.rows[1].id == lone and not P.panel.docked, "the panel on its own, the oldest sealed letter first")
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
local shown = P.rows[1].id
local q = D.letters[shown].quests[#D.letters[shown].quests]
local name = ns.questNames[q]
ns.questNames[q] = nil
P.rows[1].scripts.OnClick(P.rows[1])
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
check(YoursTrulyFrame.count:GetText():find("9", 1, true), "nine letters received")
for _, id in ipairs(ns.received()) do
  ns.openLetter(id)
  play(0.1)
end
for _, id in ipairs(ns.received()) do
  ns.read(id)
end
check(ns.readCount() == 9, "every letter received read")
check(ns.zoneLine(MAYBELL) == L["%s: %d of %d"]:format("Zone 12", 2, 2), "Elwynn's count: two of two")
check(ns.earnedMilestone("five") and ns.earnedMilestone("still-owed"), "five letters, and Gazlowe's")
check(not ns.earnedMilestone("every"), "not every letter yet: Hemet's and the later waves' still to come")
check(not ns.milestoneVisible(ns.milestoneById["hate-mail"]), "Nathanos's achievement isn't the Alliance's")
check(not ns.earnedMilestone("ten"), "nine letters: not ten yet")
if G.FOREVER then
  check(not ns.earnedMilestone("where-it-began"), "Forever: Zephras Isle's letter still to come")
else
  check(ns.earnedMilestone("where-it-began"), "every starting zone: Teldrassil, Elwynn, Dun Morogh")
end
-- (the alert's switch off for what follows: the chat lines still, no banner)
ns.setOption("achievementToast", false)
local function bannerShown()
  for i = 1, 20 do
    local b = _G["YoursTrulyBanner" .. i]
    if b and b:IsShown() then return true end
  end
  return false
end
for i = 1, 20 do
  local b = _G["YoursTrulyBanner" .. i]
  if b then b:Hide() end
end
s.printed = {}
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
do
  local due = #ns.due()
  G.mailbox(true)
  check(due > 3 and #ns.due() == due - 2, "more than three due: two a visit")
  check(P.rows[2]:IsShown(), "the second behind the first")
  local second = P.rows[2].id
  P.rows[1].scripts.OnClick(P.rows[1])
  P.back.scripts.OnClick(P.back)
  check(P.rows[1].id == second, "the first's seal broken: back to the list, the second still there")
  -- the button breaks every seal left, the list empty and the panel closed
  P.openAll.scripts.OnClick(P.openAll)
  check(#ns.waiting() == 0 and not P.panel:IsShown(), "open all: every seal broken, nothing left to list")
  G.mailbox(false)
end
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
check(
  not bannerShown() and said(L["Achievement earned: %s."]:match("^(.-)%%s")),
  "the alert's switch off: the chat lines, no banner"
)
ns.setOption("achievementToast", true)
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
  ns.earnedMilestone("twenty-five") and ns.earnedMilestone("capitals"),
  "twenty-five letters, and one from each of the side's three capitals"
)
check(ns.earnedMilestone("better-late"), "the Felstone parcel's letter, the Alliance's: Ol' Emma's")
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

-- ── a German reader, a woman ─────────────────────────────────────────────────
if G.LOCALE == "deDE" then
  s.sex = 3
  local b = ns.letter(BERNICE)
  check(b.greeting:find("Liebe Tester", 1, true), "the reader agreed to: a woman")
  check(not (b.greeting .. table.concat(b.body)):find("$g", 1, true), "no token left")
  local sol = table.concat(ns.letter(21).body, " ") -- (Magistrate Solomon's)
  local this, other = "Sturmwind", "Stormwind"
  if not G.FOREVER then
    this, other = other, this
  end
  check(
    sol:find(this, 1, true) and not sol:find(other, 1, true),
    this .. " as this client writes it, in Solomon's letter"
  )
  check(
    sol:find("Seenhain", 1, true) and sol:find("Dunkelhain", 1, true),
    "Lakeshire and Darkshire, the same on both clients"
  )
  s.sex = 2
end

-- ── a Spanish reader, a woman (esMX: esES's letters, its own names) ─────────
if G.LOCALE == "esES" or G.LOCALE == "esMX" then
  s.sex = 3
  local b = ns.letter(BERNICE)
  check(b.greeting:find("Querida Tester", 1, true), "the reader agreed to: a woman")
  check(not (b.greeting .. table.concat(b.body)):find("$g", 1, true), "no token left")
  local mx = G.LOCALE == "esMX"
  check(
    ns.letter(HEMET).signoff:find(mx and "Hemet Nesingwary" or "Hemet Decautela", 1, true),
    "Hemet as this client names him"
  )
  check(ns.letter(GAZLOWE).ps[1]:find("^P%. D%."), "the Spanish P. D.")
  local nimboya = ns.letter(56).signoff -- (Grom'gol: its capital G on Classic Era's esES client only)
  check(
    nimboya:find((not mx and not G.FOREVER) and "Grom'Gol" or "Grom'gol", 1, true),
    "Grom'gol as this client writes it"
  )
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
    and not ns.milestoneById["brush"].visible()
    and ns.milestoneById["better-late"].visible(),
  "the Horde's writers' achievements, not the Alliance's (earned ones stay listed)"
)
s.faction = nil

-- ── /yourstruly ──────────────────────────────────────────────────────────────
-- (the family's command: an unknown word prints the usage, the replies capitalised)
s.printed = {}
SlashCmdList.YOURSTRULY("nonsense")
check(said("/yourstruly"), "/yourstruly nonsense: the usage")
local hidden = ns.option("minimapHidden")
s.printed = {}
SlashCmdList.YOURSTRULY("minimap")
check(
  ns.option("minimapHidden") == not hidden
    and said(L["Minimap button hidden (%s minimap shows it again)."]:format("/yourstruly")),
  "/yourstruly minimap: the button hidden, said"
)
SlashCmdList.YOURSTRULY("minimap")
check(ns.option("minimapHidden") == hidden and said(L["Minimap button shown."]), "… and shown again")
SlashCmdList.YOURSTRULY("achievements")
check(
  YoursTrulyFrame:IsShown() and YoursTrulyFrame.selectedTab == ns.TAB.milestones,
  "/yourstruly achievements: the book at its achievements"
)

-- ── a long list: a page of seven, the pager, the page clamped ───────────────
do
  local got = ns.received()
  check(#got >= 9, "letters enough for two pages")
  for i = 1, 9 do
    char.letters[got[i]].read = nil
  end
  G.mailbox(true)
  check(#ns.waiting() == 9 and P.rows[7]:IsShown(), "nine waiting: a full page")
  check(P.next:IsShown() and P.prev:IsShown(), "the pager shown")
  local first = P.rows[1].id
  P.next.scripts.OnClick(P.next)
  check(P.rows[1].id ~= first and P.rows[2]:IsShown() and not P.rows[3]:IsShown(), "next: the two left on page two")
  P.prev.scripts.OnClick(P.prev)
  check(P.rows[1].id == first, "prev: page one again")
  P.next.scripts.OnClick(P.next)
  P.rows[1].scripts.OnClick(P.rows[1])
  P.back.scripts.OnClick(P.back)
  check(P.rows[1]:IsShown() and #ns.waiting() == 8, "back: the list, one seal fewer")
  -- (the last page emptied: back to the page before it)
  P.rows[1].scripts.OnClick(P.rows[1])
  P.back.scripts.OnClick(P.back)
  check(#ns.waiting() == 7 and P.rows[7]:IsShown(), "the last page emptied: the page clamped, one page")
  P.openAll.scripts.OnClick(P.openAll)
  check(#ns.waiting() == 0 and not P.panel:IsShown(), "open all: every page's seals broken, the panel closed")
  G.mailbox(false)
end

io.write(
  ("Yours Truly: %d checks passed (%s, %s).\n"):format(count, G.LOCALE, G.FOREVER and "Forever" or "Classic Era")
)
