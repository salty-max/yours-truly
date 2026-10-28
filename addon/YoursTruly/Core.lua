-- Yours Truly: the letters this character has earned (a chain's last quest
-- turned in posts its writer's letter), the post they wait in (fifteen
-- minutes of play, counted here), the mailbox that delivers them (the next
-- one opened, one letter a visit, two when more than three wait), the seal
-- broken; the events every file listens to (ns.on); /yourstruly. The panel
-- beside the mail window (Panel.lua) and the book (Book.lua and its tabs)
-- show them.
--
--   YoursTrulyChar (SavedVariablesPerCharacter), whose book: guid
--     played                      seconds of play counted while Yours Truly
--                                 was on (the game's own RequestTimePlayed
--                                 prints to the chat: never that)
--     letters[id] = { posted,     the played second it went in the post
--                     at, level,  when, and the character's level then
--                     backlog,    true: found done at a login, not turned in
--                     delivered,  when it reached a mailbox (or the book)
--                     bundled,    true: came in the backlog's bundle,
--                                 straight into the book
--                     read }      when its seal was broken
--     milestones[id] = { at, level, retro }   (Achievements.lua)
--   YoursTrulySettings (SavedVariables): each character's settings, the kit's
--     profiles (Settings.lua: the minimap button)
--
-- Every record by id: a letter by its id (letters/<zone>/<writer>.md), its
-- quests, writer and place by theirs; their names are the game's, in the
-- client's language, when shown.
local _, ns = ...
local L, D = ns.kit.L, ns.data
-- The kit's look (Kit.lua), in Yours Truly's theme: the red of the wax on the
-- game's sealed letter (a letter is the kit's voice, signed in it).
ns.kit.theme({
  accent = { 0.90, 0.60, 0.48 },
  ring = { 0.62, 0.32, 0.26 },
  bar = { 0.76, 0.34, 0.28 },
  tint = { 1.00, 0.95, 0.92 },
  shade = { 0.03, 0.015, 0.01, 0.55 },
  highlight = { 1.00, 0.86, 0.82 },
})

ns.PREFIX = ns.kit.prefix("Yours Truly")
-- The addon's mark (its logo: the book's and the panel's portrait, the
-- minimap button, the welcome page, the banners); its wax seal cut round
-- (Media/Seal, assets/README.md): a letter still sealed, on its envelope and in
-- the book; a letter read: the game's open letter.
ns.ICON = "Interface\\AddOns\\YoursTruly\\Media\\Logo"
ns.SEAL = "Interface\\AddOns\\YoursTruly\\Media\\Seal"
ns.ICON_READ = "Interface\\Icons\\INV_Letter_15"
-- (a letter's time in the post, in seconds played)
ns.POST = 15 * 60

local char
function ns.book() return char end

-- ── events ───────────────────────────────────────────────────────────────────
-- Every file listens through ns.on (the kit's events: each listener on its
-- own, an event a client doesn't know never heard), nothing before the login
-- has opened this character's book.
local events = ns.kit.events({ login = function() ns.login() end, ready = function() return char ~= nil end })
ns.on = events.on

-- ── the clock ────────────────────────────────────────────────────────────────
-- The time played, as Yours Truly counts it: every frame's seconds while the
-- character is logged in.
local clock = CreateFrame("Frame")
clock:SetScript("OnUpdate", function(_, elapsed)
  if char then char.played = char.played + elapsed end
end)

-- ── the letters ──────────────────────────────────────────────────────────────
-- The character's side, as the data writes it (A, H; N: both).
function ns.side() return UnitFactionGroup("player") == "Horde" and "H" or "A" end
-- The character's race and class against a letter's masks (its anchors'):
-- the kit's (a race's bit is its id's, one less, but where the data's
-- raceBits say otherwise, Forever's Skyborne). No mask: anyone.
local function canEarn(l) return ns.kit.forMe(l.races, l.classes, D.raceBits) end
-- A letter this character may receive: this game's (the data holds it), its
-- side's or both sides', its race's and class's (the Skyborne's own island).
function ns.mine(id)
  local l = D.letters[id]
  return l ~= nil and (l.side == "N" or l.side == ns.side()) and canEarn(l)
end
-- Every letter this character may receive, by id.
function ns.letters()
  local out = {}
  for id in pairs(D.letters) do
    if ns.mine(id) then table.insert(out, id) end
  end
  table.sort(out)
  return out
end

-- A quest done, as the game keeps it.
ns.done = ns.kit.questDone

-- Every quest of the letter turned in (just: one the game is turning in now,
-- which it may not have flagged yet).
local function earned(l, just)
  for _, q in ipairs(l.quests) do
    if q ~= just and not ns.done(q) then return false end
  end
  return true
end

function ns.record(id) return char and char.letters[id] end

-- Into the post.
function ns.post(id, backlog)
  if char.letters[id] then return end
  char.letters[id] =
    { posted = math.floor(char.played), at = time(), level = UnitLevel("player"), backlog = backlog or nil }
  if ns.onChange then ns.onChange() end
end

-- The letters earned before (the addon newly on, off for a while, or a new
-- wave of letters for chains already done): found at the login, quietly. One
-- alone goes by the post's rule. Two or more come as one bundle at the next
-- mailbox, with no wait: untied, they go into the book, sealed, to open
-- there when the player likes (ns.bundle, ns.untie). A level 60 installing
-- the addon gets one bundle, not a dozen visits of old news.
function ns.catchUp()
  for _, id in ipairs(ns.letters()) do
    if not char.letters[id] and earned(D.letters[id]) then ns.post(id, true) end
  end
end

-- A quest turned in: the letter it completes goes in the post.
ns.on("QUEST_TURNED_IN", function(quest)
  for _, id in ipairs(ns.letters()) do
    if not char.letters[id] then
      local l = D.letters[id]
      for _, q in ipairs(l.quests) do
        if q == quest then
          if earned(l, quest) then ns.post(id) end
          break
        end
      end
    end
  end
end)

-- (the oldest first: the post's order, then the chain's level, then the id)
local function older(a, b)
  local ra, rb = char.letters[a], char.letters[b]
  if ra.posted ~= rb.posted then return ra.posted < rb.posted end
  local la, lb = D.letters[a].level or 0, D.letters[b].level or 0
  if la ~= lb then return la < lb end
  return a < b
end

-- The bundle: the backlog's letters not yet delivered, when there are two or
-- more (one alone is a letter like any other), in the chains' order.
function ns.bundle()
  local out = {}
  for id, r in pairs(char.letters) do
    if D.letters[id] and r.backlog and not r.delivered then table.insert(out, id) end
  end
  if #out < 2 then return {} end
  table.sort(out, older)
  return out
end
-- Untied: every letter of the bundle in the book, sealed.
function ns.untie()
  local bundle = ns.bundle()
  for _, id in ipairs(bundle) do
    local r = char.letters[id]
    r.delivered, r.bundled = time(), true
  end
  if #bundle > 0 and ns.onChange then ns.onChange() end
  return #bundle
end

-- The untied bundle tied again (/yourstruly retie, to test it once more): its
-- letters back in the post as backlog, sealed and not delivered.
function ns.retie()
  local n = 0
  for _, r in pairs(char.letters) do
    if r.bundled then
      r.delivered, r.bundled, r.read = nil, nil, nil
      n = n + 1
    end
  end
  if n > 0 and ns.onChange then ns.onChange() end
  if ns.refreshMail then ns.refreshMail() end
  return n
end

-- In the post, their time up: the next mailbox may deliver them, oldest first
-- (the bundle's letters aren't: they come together).
function ns.due()
  local out, bundled = {}, {}
  for _, id in ipairs(ns.bundle()) do
    bundled[id] = true
  end
  for id, r in pairs(char.letters) do
    if D.letters[id] and not r.delivered and not bundled[id] and char.played - r.posted >= ns.POST then
      table.insert(out, id)
    end
  end
  table.sort(out, older)
  return out
end
-- Still in the post, their time not up (nothing says they're there).
function ns.inThePost()
  local n = 0
  for id, r in pairs(char.letters) do
    if D.letters[id] and not r.delivered then n = n + 1 end
  end
  return n
end
-- Delivered to the mailbox, the seal unbroken: the oldest delivered first
-- (a bundle's letters wait in the book, not at the mailbox).
function ns.waiting()
  local out = {}
  for id, r in pairs(char.letters) do
    if D.letters[id] and r.delivered and not r.read and not r.bundled then table.insert(out, id) end
  end
  table.sort(out, function(a, b)
    local da, db = char.letters[a].delivered, char.letters[b].delivered
    if da ~= db then return da < db end
    return older(a, b)
  end)
  return out
end
-- Delivered, newest first: the book's letters.
function ns.received()
  local out = {}
  for id, r in pairs(char.letters) do
    if D.letters[id] and r.delivered then table.insert(out, id) end
  end
  table.sort(out, function(a, b)
    local da, db = char.letters[a].delivered, char.letters[b].delivered
    if da ~= db then return da > db end
    return older(b, a)
  end)
  return out
end
function ns.readCount()
  local n = 0
  for id, r in pairs(char.letters) do
    if D.letters[id] and r.read then n = n + 1 end
  end
  return n
end

-- A mailbox opened: one letter of those due, two when more than three are.
function ns.deliver()
  local due = ns.due()
  local n = #due > 3 and 2 or math.min(#due, 1)
  for i = 1, n do
    char.letters[due[i]].delivered = time()
  end
  return n
end

-- The seal broken.
function ns.read(id)
  local r = char.letters[id]
  if not r or r.read then return end
  r.delivered = r.delivered or time()
  r.read = time()
  if ns.checkMilestones then ns.checkMilestones() end
  if ns.onChange then ns.onChange() end
end

-- ── the mailbox ──────────────────────────────────────────────────────────────
-- A visit: from the mailbox opened to the mailbox closed (MAIL_SHOW may come
-- again within it). The panel a moment later: the game opens its mail window
-- on an event of its own (the interaction manager's), in no order against
-- this one, and the panel docks to it.
local visiting = false
ns.on("MAIL_SHOW", function()
  if visiting then return end
  visiting = true
  ns.deliver()
  C_Timer.After(0, function()
    if not visiting or (#ns.waiting() == 0 and #ns.bundle() == 0) then return end
    -- (the rows in the game's own inbox, else the panel by itself)
    if ns.atMailbox and ns.atMailbox() then return end
    if ns.showPanel then ns.showPanel() end
  end)
  if ns.onChange then ns.onChange() end
end)
ns.on("MAIL_CLOSED", function()
  visiting = false
  if ns.hidePanel then ns.hidePanel() end
end)

-- ── a letter's words ─────────────────────────────────────────────────────────
-- As this client's language writes it (Letters_<locale>): Classic Era's
-- names swapped in there, agreed to the reader, the game's tokens filled.
local function swapped(text)
  if ns.forever or not ns.classicNames then return text end
  return ns.kit.swap(text, ns.classicNames) -- (the longest first, found as written)
end
local function filled(text)
  local name = UnitName("player")
  local class, classFile = UnitClass("player")
  if UnitSex("player") == 3 and LOCALIZED_CLASS_NAMES_FEMALE and classFile then
    class = LOCALIZED_CLASS_NAMES_FEMALE[classFile] or class
  end
  local race = UnitRace("player")
  return (text:gsub("%$([NCR])", { N = name or "", C = class or "", R = race or "" }))
end
local function fit(text) return filled(ns.agree(swapped(text))) end

-- { greeting, body = { ... }, signoff, ps = { ... } }, or nil.
function ns.letter(id)
  local t = ns.letterTexts and ns.letterTexts[id]
  if not t then return nil end
  local body, ps = {}, {}
  for i, p in ipairs(t.body) do
    body[i] = fit(p)
  end
  for i, p in ipairs(t.ps or {}) do
    ps[i] = fit(p)
  end
  return { greeting = fit(t.greeting), body = body, signoff = fit(t.signoff), ps = ps }
end

-- The writer's name, the game's (a letter's writer always has one in English,
-- the build refuses one without; a language lacking it: "a friend", never an
-- English name in its place, the family's rule).
function ns.writer(id)
  local l = D.letters[id]
  return l and ns.npcNames and ns.npcNames[l.npc] or L["A friend"]
end
-- A place's name, the client's (an area id).
function ns.areaName(area) return ns.kit.areaName(area) end
function ns.place(id)
  local l = D.letters[id]
  return l and ns.areaName(l.place) or ""
end
-- The chain a letter answers: its last quest's name (nil: this language lacks it).
function ns.chain(id)
  local l = D.letters[id]
  local q = l and l.quests[#l.quests]
  return q and ns.questNames and ns.questNames[q] or nil
end
-- A zone's count: the letters it has sent this character, and all it could.
function ns.zoneCount(zone)
  local got, all = 0, 0
  for _, id in ipairs(ns.letters()) do
    if D.letters[id].zone == zone then
      all = all + 1
      local r = char.letters[id]
      if r and r.delivered then got = got + 1 end
    end
  end
  return got, all
end
-- "Westfall: 1 of 2", once the zone has written (never before: no one
-- else's name or number is given away).
function ns.zoneLine(id)
  local l = D.letters[id]
  local got, all = ns.zoneCount(l.zone)
  if got == 0 then return nil end
  return L["%s: %d of %d"]:format(ns.areaName(l.zone) or "", got, all)
end

-- ── the login ────────────────────────────────────────────────────────────────
local function newBook(guid) return { guid = guid, played = 0, letters = {}, milestones = {} } end

function ns.login()
  local guid = UnitGUID("player")
  if type(YoursTrulyChar) ~= "table" or YoursTrulyChar.guid ~= guid then YoursTrulyChar = newBook(guid) end
  char = YoursTrulyChar
  char.played = tonumber(char.played) or 0
  char.letters, char.milestones = char.letters or {}, char.milestones or {}
  ns.loadProfile()
  if ns.createMinimapButton then ns.createMinimapButton() end
  if ns.createSettingsPanel then ns.createSettingsPanel() end
  ns.catchUp()
  if ns.checkMilestones then ns.checkMilestones(true) end
  ns.loggedIn = true
end

-- ── /yourstruly ──────────────────────────────────────────────────────────────
-- The kit's command (K.commands): alone it opens the book, an unknown word
-- prints the usage.
ns.kit.commands({
  names = { "/yourstruly" },
  key = "YOURSTRULY",
  name = "Yours Truly",
  prefix = ns.PREFIX,
  profiles = function() return ns.profiles end, -- (Settings.lua makes them, after this file)
  open = function()
    if ns.toggle then ns.toggle() end
  end,
  usage = L["/yourstruly opens the book, /yourstruly achievements its achievements and /yourstruly settings its settings. /yourstruly minimap shows or hides the button, /yourstruly welcome shows the welcome page again. /yourstruly export gives this character's settings as a code, and /yourstruly import CODE takes them."],
  settings = function() return ns.openSettings() end,
  welcome = function(mode)
    if ns.showWelcome then ns.showWelcome(mode) end
  end,
  -- (looked up when used: Settings.lua makes them, after this file)
  minimap = { get = function(k) return ns.option(k) end, set = function(k, v) ns.setOption(k, v) end },
  commands = {
    achievements = function()
      if ns.openMilestones then ns.openMilestones() end
    end,
    -- (a test aid, not in the usage: the bundled letters tied up again, as
    -- unread backlog, to untie the bundle once more)
    retie = function()
      local n = ns.retie()
      print(ns.kit.plural(n, "%d letter", "%d letters"):format(n))
    end,
  },
})
