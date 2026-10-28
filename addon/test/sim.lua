-- Yours Truly played through: a first login with nothing done, a chain's last
-- quest turned in (its letter in the post, fifteen minutes of play, then the
-- next mailbox), the sealed envelope and its seal broken, the other side's
-- letters held back, the backlog found at a login and come as one bundle
-- (untied straight into the book, sealed, the panel closed, a fresh letter
-- still behind it, its seal broken by the page's button, a backlog of
-- one by the post), the mailbox's pace (one a visit, two when more than three
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
check(not ns.mailBadgeShown() or MiniMapMailFrame:IsShown(), "(and our own stands in only without it)")
MiniMapMailFrame.scripts.OnEvent(MiniMapMailFrame, "UPDATE_PENDING_MAIL")
check(MiniMapMailFrame:IsShown(), "the game hides it on its event, no real mail: ours shows it again")
s.newMail = true
ns.refreshMail()
s.newMail = nil
G.mailbox(true)
local R = ns.inboxRows()
check(
  R.strip:IsShown() and R[1]:IsShown() and not (R[2] and R[2]:IsShown()),
  "the letter is one row on the inbox strip, no panel yet"
)
check(
  R[1].name:GetText() == ns.writer(IVERRON) and R[1].subject:GetText() == ns.place(IVERRON),
  "the writer and the place on it"
)
check(not ns.panelLetter(), "the panel waits for a click")
check(ns.mailBadgeShown(), "delivered and unread: the icon still there")
R[1].scripts.OnEnter(R[1])
check(
  GameTooltip.lines[#GameTooltip.lines] == L["Not real mail: it can't be taken, deleted or returned."],
  "its tooltip says it is not mail"
)
InboxFrame.pageNum = 2
G.inboxUpdate()
check(not R.strip:IsShown(), "a later page of the inbox: no strip")
InboxFrame.pageNum = 1
G.inboxUpdate()
check(R.strip:IsShown(), "back on the first: the strip again")
ns.showPanel()
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

-- ── the backlog: one bundle ─────────────────────────────────────────────────
for _, q in ipairs({ 166, 700, 114, 87, 414, 6163 }) do
  s.done[q] = true
end
G.login()
check(char.letters[GRYAN] and char.letters[GRYAN].backlog, "a chain done before: found at the login")
check(not char.letters[NATHANOS], "not the other side's")
check(#s.printed == 0 or not said("letter"), "quietly")
check(#ns.bundle() == 5, "five found: one bundle")
play(ns.POST + 1)
check(#ns.due() == 1 and ns.due()[1] == GAZLOWE, "the bundle's letters aren't in the post: only the fresh one is due")
G.mailbox(true)
ns.showPanel() -- (a click on the strip's first row)
check(char.letters[GAZLOWE].delivered, "a fresh letter still comes by the post")
check(not char.letters[GRYAN].delivered, "the bundle not untied yet")
check(ns.panelLetter() == "bundle", "the bundle first in the panel")
check(P.writer:GetText():find("5", 1, true), "its count on it")
check(P.next:IsShown(), "and the fresh letter behind it")
P.next.scripts.OnClick(P.next)
check(ns.panelLetter() == GAZLOWE and P.next:IsShown(), "next: the fresh letter, sealed, the bundle still behind it")
P.next.scripts.OnClick(P.next)
check(ns.panelLetter() == "bundle", "next: back to the bundle")
G.mailbox(false)
G.mailbox(true)
ns.showPanel() -- (a click on the strip's first row)
check(ns.panelLetter() == "bundle", "the next visit: the bundle still there, untouched")
local firstBundled = ns.bundle()[1]
P.envelope.scripts.OnClick(P.envelope)
check(not P.panel:IsShown(), "untied: the panel closed, no page in between")
check(
  YoursTrulyFrame and YoursTrulyFrame:IsShown() and YoursTrulyFrame.selectedTab == ns.TAB.letters,
  "untied: the book open at its letters"
)
for _, id in ipairs({ GRYAN, SARA, MAYBELL, BERNICE, REJOLD }) do
  local r = char.letters[id]
  check(r.delivered and r.bundled and not r.read, "into the book, sealed: " .. id)
end
check(
  #ns.bundle() == 0 and #ns.waiting() == 1 and ns.waiting()[1] == GAZLOWE,
  "the bundle gone, the fresh letter still waiting at the mailbox, sealed"
)
-- (the bundle's first, sealed in the book: a button breaks its seal)
local letterPage = YoursTrulyLetterPage
local seal = letterPage.buttonPool[1]
check(
  seal and seal:IsShown() and seal.text == L["Break the seal"] and not letterPage.chipPool[1],
  "a sealed letter in the book: a button, not a chip"
)
seal.scripts.OnClick(seal)
check(char.letters[firstBundled].read, "the button breaks the seal: " .. firstBundled)
local voice = letterPage.voices[1]
check(
  voice and voice:IsShown() and voice.sign:GetText() == ns.letter(firstBundled).signoff and #letterPage.asides == 0,
  "the letter in the book: the kit's voice, signed, no aside"
)
char.letters[firstBundled].read = nil
YoursTrulyFrame:Hide()
G.mailbox(false)
G.mailbox(true)
ns.showPanel() -- (a click on the strip's first row)
check(ns.panelLetter() == GAZLOWE and not P.next:IsShown(), "the next visit: the fresh letter, and nothing behind it")
P.envelope.scripts.OnClick(P.envelope)
check(char.letters[GAZLOWE].read, "its seal broken at the mailbox")
G.mailbox(false)
G.mailbox(true)
check(not ns.panelLetter(), "the visit after: no panel, the bundle's letters in the book")
G.mailbox(false)
-- (one alone is a letter like any other: by the post)
local lone = 20 -- (Hinderweir's: A Dark Threat Looms)
s.done[283] = true
G.login()
check(char.letters[lone] and char.letters[lone].backlog and #ns.bundle() == 0, "a backlog of one: no bundle")
play(ns.POST + 1)
check(ns.due()[1] == lone, "it goes by the post")
G.mailbox(true)
check(char.letters[lone].delivered and not char.letters[lone].bundled, "and reaches the mailbox as a letter")
G.mailbox(false)

-- ── a mailbox addon: the game's window hidden ────────────────────────────────
G.turnIn(930) -- (The Glowing Fruit)
play(ns.POST + 1)
s.noMailFrame = true
G.mailbox(true)
check(char.letters[DENALAN].delivered, "delivered without the game's mail window")
check(ns.panelLetter() == lone and not P.panel.docked, "the panel on its own, the oldest sealed letter first")
G.mailbox(false)
s.noMailFrame = nil
-- (a mailbox addon that keeps the game's window open but transparent)
G.turnIn(5441) -- (nothing for the Alliance: no new letter, the sealed ones still wait)
MailFrame:SetAlpha(0)
G.mailbox(true)
check(ns.panelLetter() and not P.panel.docked, "a transparent mail window: the panel on its own")
G.mailbox(false)
MailFrame:SetAlpha(1)
-- (the screen's foot leaving no room under the window: the panel on its own)
s.mailFoot = 40
G.mailbox(true)
check(
  not ns.inboxServes() and ns.panelLetter(),
  "no room under the mail window: the panel, as when a mailbox addon hides it"
)
G.mailbox(false)
check(not (ns.inboxRows().strip:IsShown()), "the mailbox closed: no strip")
s.mailFoot = nil
-- (the inbox left on page 2: no strip, so the panel stands and the letter is not lost)
InboxFrame.pageNum = 2
G.mailbox(true)
check(ns.panelLetter(), "a mailbox on page 2 of the inbox: the panel stands, not nothing")
G.mailbox(false)
InboxFrame.pageNum = 1
-- (the strip at a mailbox: a row a letter, a click breaks the seal and opens it)
G.mailbox(true)
do
  local q = ns.queue()
  local R = ns.inboxRows()
  local shownRows = (R[1] and R[1]:IsShown() and 1 or 0) + (R[2] and R[2]:IsShown() and 1 or 0)
  check(#q > 0 and shownRows == math.min(#q, 2), "a row each, two at most")
  if #q > 2 then
    check(R[2].name:GetText():find(tostring(#q - 1), 1, true), "more than two: the second row counts the rest")
  end
  local first = q[1]
  R[1].scripts.OnClick(R[1])
  if first ~= "bundle" then
    check(
      char.letters[first].read and ns.panelLetter() == first and P.scroll:IsShown(),
      "a click on a letter's row opens it"
    )
    check(#ns.queue() == #q - 1, "and the row goes")
  else
    check(ns.panelLetter() == "bundle" and P.envelope:IsShown(), "a click on the bundle's row shows the bundle tied")
  end
  G.mailbox(false)
end
-- (a language lacking the chain's name: the footer without it, no error)
G.mailbox(true)
ns.showPanel() -- (a click on the strip's first row)
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
  ns.showPanel() -- (a click on the strip's first row)
  check(due > 3 and #ns.due() == due - 2, "more than three due: two a visit")
  check(P.next:IsShown(), "the second behind the first")
  P.envelope.scripts.OnClick(P.envelope)
  check(P.next:IsShown(), "the first's seal broken: the second still reachable")
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

io.write(
  ("Yours Truly: %d checks passed (%s, %s).\n"):format(count, G.LOCALE, G.FOREVER and "Forever" or "Classic Era")
)
